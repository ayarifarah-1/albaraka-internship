import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  OnInit,
  ViewChild,
  computed,
  inject,
  signal,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../services/auth.service';
import {
  RaglabEnvFileInfo,
  RaglabEnvKeyItem,
  RaglabProfile,
  RaglabProviderInfo,
  RaglabSanityResponse,
  RaglabService,
} from '../../../services/raglab.service';

const CUSTOM_KEY_ENV_RE = /^[A-Z][A-Z0-9_]{0,62}_(?:API_KEY|KEY)(?:_[A-Z0-9_]{1,30})?$/;
const RESERVED_ENV_PREFIXES = [
  'RAGLAB_',
  'HARNESS_',
  'PYTHON',
  'LD_',
  'PATH',
  'SSL_',
  'HTTP_',
  'HTTPS_',
  'NO_PROXY',
  'ALL_PROXY',
  'CHROMA',
  'TIKTOKEN',
  'UVICORN',
  'FASTAPI',
  'STARLETTE',
  'SUFFICIENCY_',
  'ANSWER_',
  'EMBEDDING_',
  'CHUNKING_',
  'CHUNK_',
  'QUERY_',
  'LEXICON_',
  'RERANK_',
  'RELATIONAL_',
  'REPHRASE_',
  'PER_MICRO_',
  'SOFT_REFUSAL_',
  'AUDIT_',
  'RETRIEVAL_',
  'HYBRID_',
  'KEYWORD_',
  'FUSION_',
];

@Component({
  selector: 'app-raglab-settings',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './raglab-settings.component.html',
  styleUrl: './raglab-settings.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RaglabSettingsComponent implements OnInit {
  public readonly raglab = inject(RaglabService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly destroyRef = inject(DestroyRef);

  @ViewChild('secretKeyInput') secretKeyInput?: ElementRef<HTMLInputElement>;

  readonly canManage = this.auth.hasPermission('RAGLAB_CONSOLE_MANAGE');
  readonly activeTab = signal<'models' | 'keys'>('models');

  // Models & Profile
  readonly embeddingProviders = signal<RaglabProviderInfo[]>([]);
  readonly answerProviders = signal<RaglabProviderInfo[]>([]);
  readonly profile = signal<RaglabProfile | null>(null);
  readonly switchingEnabled = signal(true);
  readonly isLoadingModels = signal(false);
  readonly isSavingModels = signal(false);
  readonly modelsMessage = signal<{ type: 'ok' | 'err' | 'warn'; text: string } | null>(null);
  readonly indexDriftPrompt = signal(false);

  // Draft selections
  readonly embProvider = signal('');
  readonly embModel = signal('');
  readonly embCustomModel = signal('');
  readonly ansProvider = signal('');
  readonly ansModel = signal('');
  readonly ansCustomModel = signal('');

  // API Keys (.env-backed)
  readonly keys = signal<RaglabEnvKeyItem[]>([]);
  readonly envFileInfo = signal<RaglabEnvFileInfo | null>(null);
  readonly envEndpointSupported = signal(true);
  readonly isLoadingKeys = signal(false);
  readonly keyMode = signal<'registered' | 'custom'>('registered');
  readonly selectedKeyEnv = signal('');
  readonly customKeyEnv = signal('');
  readonly keyValue = signal('');
  /** Persist directly to raglab/.env by default when setting or rotating keys. */
  readonly keyPersist = signal(true);
  readonly showSecret = signal(false);
  readonly isSavingKey = signal(false);
  readonly keyMessage = signal<{ type: 'ok' | 'err'; text: string } | null>(null);
  readonly deleteConfirmKey = signal<string | null>(null);
  readonly deleteFromEnv = signal(true);
  private pendingDeepLinkKey: string | null = null;

  // Sanity check
  readonly isTestingSanity = signal(false);
  readonly sanityResult = signal<RaglabSanityResponse | null>(null);
  readonly sanityError = signal<string | null>(null);

  readonly configuredKeysCount = computed(
    () => this.keys().filter((k) => k.status === 'set').length
  );

  readonly persistedKeysCount = computed(
    () => this.keys().filter((k) => k.in_env_file).length
  );

  readonly activeTargetEnv = computed(() =>
    this.keyMode() === 'custom' ? this.customKeyEnv().trim() : this.selectedKeyEnv().trim()
  );

  readonly selectedKeyMeta = computed(
    () => this.keys().find((k) => k.env === this.activeTargetEnv()) ?? null
  );

  readonly customKeyValidationError = computed<string | null>(() => {
    if (this.keyMode() !== 'custom') return null;
    const raw = this.customKeyEnv().trim();
    if (!raw) return null;
    if (RESERVED_ENV_PREFIXES.some((prefix) => raw.startsWith(prefix))) {
      return 'Les variables internes RAGLab et système (ex. RAGLAB_*) sont réservées.';
    }
    if (!CUSTOM_KEY_ENV_RE.test(raw)) {
      return 'Utilisez des majuscules se terminant par _API_KEY ou _KEY (ex. OPENROUTER_API_KEY).';
    }
    return null;
  });

  ngOnInit(): void {
    this.route.queryParamMap
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((params) => {
        const tab = params.get('tab');
        if (tab === 'keys' || tab === 'models') {
          this.activeTab.set(tab);
        }
        const wantedKey = params.get('key')?.trim();
        if (wantedKey) {
          this.activeTab.set('keys');
          this.applyKeySelection(wantedKey);
        }
      });

    this.loadModelsAndProfile();
    this.loadKeys();
  }

  setTab(tab: 'models' | 'keys'): void {
    this.activeTab.set(tab);
    this.showSecret.set(false);
    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab, key: null },
      queryParamsHandling: 'merge',
      replaceUrl: true,
    });
  }

  openKeyEditor(envName?: string): void {
    this.activeTab.set('keys');
    this.keyMessage.set(null);
    this.showSecret.set(false);
    if (envName) {
      this.applyKeySelection(envName);
    }
    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab: 'keys', key: envName || null },
      queryParamsHandling: 'merge',
      replaceUrl: true,
    });
    this.focusSecretInput();
  }

  selectKeyForEdit(item: RaglabEnvKeyItem): void {
    this.keyMessage.set(null);
    this.keyValue.set('');
    this.showSecret.set(false);
    this.keyMode.set('registered');
    this.selectedKeyEnv.set(item.env);
    this.focusSecretInput();
  }

  setKeyMode(mode: 'registered' | 'custom'): void {
    this.keyMode.set(mode);
    this.keyMessage.set(null);
    this.showSecret.set(false);
  }

  onCustomKeyEnvChange(raw: string): void {
    const normalized = (raw || '').toUpperCase().replace(/[^A-Z0-9_]/g, '');
    this.customKeyEnv.set(normalized);
  }

  toggleShowSecret(): void {
    this.showSecret.update((v) => !v);
  }

  private applyKeySelection(envName: string): void {
    const list = this.keys();
    if (!list.length) {
      this.pendingDeepLinkKey = envName;
      return;
    }
    const existing = list.find((k) => k.env === envName);
    if (existing) {
      this.keyMode.set('registered');
      this.selectedKeyEnv.set(existing.env);
    } else if (this.envEndpointSupported()) {
      this.keyMode.set('custom');
      this.onCustomKeyEnvChange(envName);
    }
  }

  private focusSecretInput(): void {
    setTimeout(() => {
      this.secretKeyInput?.nativeElement?.focus();
    }, 0);
  }

  loadModelsAndProfile(): void {
    this.isLoadingModels.set(true);
    this.raglab.getModels().subscribe({
      next: (models) => {
        this.embeddingProviders.set(models.embedding || []);
        this.answerProviders.set(models.answer || []);
        this.raglab.getProfile().subscribe({
          next: (profRes) => {
            this.isLoadingModels.set(false);
            const p = profRes.profile;
            this.profile.set(p);
            this.switchingEnabled.set(!profRes.switching?.includes('disabled'));
            this.embProvider.set(p.embedding.provider);
            this.embModel.set(p.embedding.model);
            this.ansProvider.set(p.answer.provider);
            this.ansModel.set(p.answer.model);
          },
          error: () => this.isLoadingModels.set(false),
        });
      },
      error: () => this.isLoadingModels.set(false),
    });
  }

  get selectedEmbProviderInfo(): RaglabProviderInfo | undefined {
    return this.embeddingProviders().find((p) => p.provider === this.embProvider());
  }

  get selectedAnsProviderInfo(): RaglabProviderInfo | undefined {
    return this.answerProviders().find((p) => p.provider === this.ansProvider());
  }

  onEmbProviderChange(prov: string): void {
    this.embProvider.set(prov);
    const info = this.embeddingProviders().find((p) => p.provider === prov);
    if (info && info.models.length > 0) {
      this.embModel.set(info.models[0]);
    } else {
      this.embModel.set('');
    }
  }

  onAnsProviderChange(prov: string): void {
    this.ansProvider.set(prov);
    const info = this.answerProviders().find((p) => p.provider === prov);
    if (info && info.models.length > 0) {
      this.ansModel.set(info.models[0]);
    } else {
      this.ansModel.set('');
    }
  }

  saveModels(): void {
    if (!this.canManage || !this.switchingEnabled() || this.raglab.isSealed()) return;
    this.isSavingModels.set(true);
    this.modelsMessage.set(null);
    this.indexDriftPrompt.set(false);

    const finalEmbModel = this.embCustomModel().trim() || this.embModel();
    const finalAnsModel = this.ansCustomModel().trim() || this.ansModel();
    const prevEmb = this.profile()?.embedding;
    const embChanged =
      prevEmb && (prevEmb.provider !== this.embProvider() || prevEmb.model !== finalEmbModel);

    this.raglab
      .updateProfile({
        embedding: { provider: this.embProvider(), model: finalEmbModel },
        answer: { provider: this.ansProvider(), model: finalAnsModel },
      })
      .subscribe({
        next: (res) => {
          this.isSavingModels.set(false);
          this.profile.set(res.profile);
          this.embCustomModel.set('');
          this.ansCustomModel.set('');
          const notes = res.notes?.length ? ' (' + res.notes.join(' ; ') + ')' : '';
          this.modelsMessage.set({
            type: 'ok',
            text: `Profil mis à jour. Collection : ${res.collection}${notes}`,
          });
          if (embChanged) {
            this.indexDriftPrompt.set(true);
          }
          this.loadModelsAndProfile();
        },
        error: (err) => {
          this.isSavingModels.set(false);
          const msg = err?.error?.message || 'Erreur lors du changement de profil.';
          this.modelsMessage.set({ type: 'err', text: msg });
        },
      });
  }

  loadKeys(): void {
    this.isLoadingKeys.set(true);
    this.raglab.getEnvKeys().subscribe({
      next: (res) => {
        this.isLoadingKeys.set(false);
        this.envEndpointSupported.set(true);
        this.envFileInfo.set(res.env_file ?? null);
        this.applyLoadedKeys(res.keys || []);
      },
      error: () => {
        // Rolling-upgrade fallback against RAGLab < 1.6.0
        this.raglab.getKeys().subscribe({
          next: (legacy) => {
            this.isLoadingKeys.set(false);
            this.envEndpointSupported.set(false);
            this.envFileInfo.set(null);
            this.applyLoadedKeys(
              (legacy.keys || []).map((k) => ({ ...k, registered: true }))
            );
          },
          error: () => this.isLoadingKeys.set(false),
        });
      },
    });
  }

  private applyLoadedKeys(items: RaglabEnvKeyItem[]): void {
    this.keys.set(items);
    if (this.pendingDeepLinkKey) {
      const wanted = this.pendingDeepLinkKey;
      this.pendingDeepLinkKey = null;
      this.applyKeySelection(wanted);
      return;
    }
    const current = this.selectedKeyEnv();
    if ((!current || !items.some((k) => k.env === current)) && items.length > 0) {
      this.selectedKeyEnv.set(items[0].env);
    }
  }

  saveKey(): void {
    if (!this.canManage) return;
    const env = this.activeTargetEnv();
    const val = this.keyValue().trim();

    if (!env) {
      this.keyMessage.set({
        type: 'err',
        text: 'Veuillez sélectionner ou saisir le nom de la variable de clé API.',
      });
      return;
    }
    if (this.keyMode() === 'custom') {
      if (!this.envEndpointSupported()) {
        this.keyMessage.set({
          type: 'err',
          text: 'Les clés personnalisées nécessitent RAGLab 1.6.0+ (/env/keys).',
        });
        return;
      }
      const nameErr = this.customKeyValidationError();
      if (nameErr) {
        this.keyMessage.set({ type: 'err', text: nameErr });
        return;
      }
    }
    if (!val) {
      this.keyMessage.set({ type: 'err', text: 'Veuillez saisir une valeur de clé API.' });
      return;
    }
    if (/[\s"']/.test(val)) {
      this.keyMessage.set({
        type: 'err',
        text: 'Une clé API ne peut contenir ni espaces ni guillemets.',
      });
      return;
    }
    if (val.length < 8) {
      this.keyMessage.set({
        type: 'err',
        text: 'La clé saisie est trop courte (minimum 8 caractères).',
      });
      return;
    }

    this.isSavingKey.set(true);
    this.keyMessage.set(null);

    const persist = this.keyPersist();
    const request$ = this.envEndpointSupported()
      ? this.raglab.setEnvKey(env, val, persist)
      : this.raglab.setKey(env, val, persist);

    request$.subscribe({
      next: () => {
        this.isSavingKey.set(false);
        this.keyValue.set('');
        this.showSecret.set(false);
        if (this.keyMode() === 'custom') {
          this.customKeyEnv.set('');
          this.keyMode.set('registered');
          this.selectedKeyEnv.set(env);
        }
        this.keyMessage.set({
          type: 'ok',
          text: persist
            ? `Clé ${env} enregistrée dans raglab/.env et activée immédiatement.`
            : `Clé ${env} activée en mémoire du service (non écrite dans raglab/.env).`,
        });
        this.loadKeys();
        this.loadModelsAndProfile();
      },
      error: (err) => {
        this.isSavingKey.set(false);
        const msg =
          err?.error?.message ||
          err?.error?.detail?.hint ||
          "Valeur invalide ou écriture dans raglab/.env impossible.";
        this.keyMessage.set({ type: 'err', text: msg });
      },
    });
  }

  confirmDeleteKey(env: string): void {
    const item = this.keys().find((k) => k.env === env);
    this.deleteFromEnv.set(item?.in_env_file !== false);
    this.deleteConfirmKey.set(env);
  }

  cancelDeleteKey(): void {
    this.deleteConfirmKey.set(null);
  }

  executeDeleteKey(): void {
    const env = this.deleteConfirmKey();
    if (!env || !this.canManage) return;
    const persist = this.deleteFromEnv();
    this.deleteConfirmKey.set(null);

    const request$ = this.envEndpointSupported()
      ? this.raglab.deleteEnvKey(env, persist)
      : this.raglab.deleteKey(env, persist);

    request$.subscribe({
      next: () => {
        this.keyMessage.set({
          type: 'ok',
          text: persist
            ? `Clé ${env} supprimée du service et retirée de raglab/.env.`
            : `Clé ${env} retirée de la mémoire du service.`,
        });
        this.loadKeys();
        this.loadModelsAndProfile();
      },
      error: (err) => {
        this.keyMessage.set({
          type: 'err',
          text: err?.error?.message || 'Erreur lors de la suppression.',
        });
      },
    });
  }

  runSanityTest(): void {
    if (this.raglab.isSealed()) return;
    this.isTestingSanity.set(true);
    this.sanityError.set(null);
    this.sanityResult.set(null);

    this.raglab.embeddingsSanity().subscribe({
      next: (res) => {
        this.isTestingSanity.set(false);
        this.sanityResult.set(res);
      },
      error: (err) => {
        this.isTestingSanity.set(false);
        this.sanityError.set(
          err?.error?.message || "Échec du test d'embeddings (clé manquante ou quota atteint)."
        );
      },
    });
  }
}
