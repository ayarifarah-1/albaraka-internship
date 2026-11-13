import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ActivatedRoute, convertToParamMap, provideRouter } from '@angular/router';
import { BehaviorSubject, of, throwError } from 'rxjs';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { signal } from '@angular/core';
import { RaglabSettingsComponent } from './raglab-settings.component';
import { RaglabService } from '../../../services/raglab.service';
import { AuthService } from '../../../services/auth.service';

describe('RaglabSettingsComponent (.env API key management)', () => {
  let fixture: ComponentFixture<RaglabSettingsComponent>;
  let component: RaglabSettingsComponent;
  let queryParams$: BehaviorSubject<ReturnType<typeof convertToParamMap>>;
  let mockRaglab: Record<string, any>;

  beforeEach(async () => {
    queryParams$ = new BehaviorSubject(
      convertToParamMap({ tab: 'keys', key: 'XKIRO_API_KEY' })
    );

    mockRaglab = {
      missingKeys: signal(['XKIRO_API_KEY']),
      isPinnedPipeline: signal(true),
      isSealed: signal(false),
      getModels: vi.fn().mockReturnValue(
        of({
          embedding: [{ provider: 'nvidia', label: 'NVIDIA', key_envs: ['NVIDIA_API_KEY'], key_set: true, models: ['m1'] }],
          answer: [{ provider: 'xkiro', label: 'xKiro', key_envs: ['XKIRO_API_KEY'], key_set: false, models: ['q1'] }],
        })
      ),
      getProfile: vi.fn().mockReturnValue(
        of({
          profile: {
            embedding: { provider: 'nvidia', model: 'm1' },
            answer: { provider: 'xkiro', model: 'q1' },
            chunking: { mode: 'restructure', size: 220, overlap: 40 },
            retrieval: { top_k: 5, mode: 'vector' },
          },
          collection: 'col',
          switching: 'enabled',
        })
      ),
      getEnvKeys: vi.fn().mockReturnValue(
        of({
          env_file: { path: 'raglab/.env', exists: true, writable: true },
          keys: [
            {
              env: 'NVIDIA_API_KEY',
              description: 'NVIDIA NIM',
              registered: true,
              status: 'set',
              in_process: true,
              in_env_file: true,
              masked: 'nvapi-12…',
            },
            {
              env: 'XKIRO_API_KEY',
              description: 'xKiro gateway',
              registered: true,
              status: 'missing',
              in_process: false,
              in_env_file: false,
              masked: null,
            },
          ],
        })
      ),
      getKeys: vi.fn(),
      setEnvKey: vi.fn().mockReturnValue(of({ env: 'XKIRO_API_KEY', status: 'set', persisted: true })),
      deleteEnvKey: vi.fn().mockReturnValue(of({ env: 'NVIDIA_API_KEY', status: 'missing', removed_from_env_file: true })),
    };

    const mockAuth = {
      hasPermission: vi.fn().mockReturnValue(true),
    };

    await TestBed.configureTestingModule({
      imports: [RaglabSettingsComponent],
      providers: [
        provideRouter([]),
        { provide: RaglabService, useValue: mockRaglab },
        { provide: AuthService, useValue: mockAuth },
        {
          provide: ActivatedRoute,
          useValue: {
            queryParamMap: queryParams$.asObservable(),
            snapshot: { queryParamMap: queryParams$.value },
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(RaglabSettingsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('opens the keys tab via query params, defaults keyPersist to true, and saves to raglab/.env', () => {
    expect(component.activeTab()).toBe('keys');
    expect(component.selectedKeyEnv()).toBe('XKIRO_API_KEY');
    expect(component.keyPersist()).toBe(true);

    component.keyValue.set('xkiro-live-secret-987654');
    component.saveKey();

    expect(mockRaglab['setEnvKey']).toHaveBeenCalledWith(
      'XKIRO_API_KEY',
      'xkiro-live-secret-987654',
      true
    );
    expect(component.keyValue()).toBe('');
    expect(component.keyMessage()?.type).toBe('ok');
  });

  it('supports adding custom *_API_KEY variables and blocks reserved RAGLAB_* names', () => {
    component.setKeyMode('custom');
    component.onCustomKeyEnvChange('raglab_service_token');
    expect(component.customKeyEnv()).toBe('RAGLAB_SERVICE_TOKEN');
    expect(component.customKeyValidationError()).toContain('réservées');

    component.keyValue.set('some-valid-secret-12345');
    component.saveKey();
    expect(mockRaglab['setEnvKey']).not.toHaveBeenCalled();

    component.onCustomKeyEnvChange('openrouter_api_key');
    expect(component.customKeyEnv()).toBe('OPENROUTER_API_KEY');
    expect(component.customKeyValidationError()).toBeNull();

    component.saveKey();
    expect(mockRaglab['setEnvKey']).toHaveBeenCalledWith(
      'OPENROUTER_API_KEY',
      'some-valid-secret-12345',
      true
    );
  });

  it('deletes from both live process and raglab/.env by default', () => {
    component.confirmDeleteKey('NVIDIA_API_KEY');
    expect(component.deleteConfirmKey()).toBe('NVIDIA_API_KEY');
    expect(component.deleteFromEnv()).toBe(true);

    component.executeDeleteKey();
    expect(mockRaglab['deleteEnvKey']).toHaveBeenCalledWith('NVIDIA_API_KEY', true);
  });

  it('falls back gracefully to /keys when /env/keys is unavailable', () => {
    mockRaglab['getEnvKeys'].mockReturnValueOnce(throwError(() => ({ status: 404 })));
    mockRaglab['getKeys'].mockReturnValueOnce(
      of({ keys: [{ env: 'NVIDIA_API_KEY', description: 'NIM', status: 'set', masked: 'nvapi-12…' }] })
    );
    component.loadKeys();
    expect(component.envEndpointSupported()).toBe(false);
    expect(component.keys().length).toBe(1);
  });
});
