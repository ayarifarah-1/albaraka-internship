import { Component, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import { toSignal } from '@angular/core/rxjs-interop';

const TITLES: Record<string, { title: string; section: string }> = {
  dashboard: { title: 'Tableau de bord', section: 'Pilotage' },
  stats: { title: "Statistiques d'usage", section: 'Pilotage' },
  monitoring: { title: 'Monitoring du chat', section: 'Pilotage' },
  raglab: { title: 'Console RAGLab', section: 'Assistant IA' },
  agent: { title: 'Santé & diagnostic', section: 'Assistant IA' },
  users: { title: 'Utilisateurs & rôles', section: 'Administration' },
  roles: { title: 'Rôles & permissions', section: 'Administration' },
  historique: { title: 'Historique clients', section: 'Administration' },
  news: { title: 'Actualités', section: 'Administration' },
  chat: { title: 'Assistant', section: 'Espace client' },
};

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './header.html',
  styleUrl: './header.css',
})
export class Header {
  private router = inject(Router);
  private url = toSignal(
    this.router.events.pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd)),
    { initialValue: null }
  );
  readonly now = signal(new Date());

  readonly crumb = computed(() => {
    const u = (this.url()?.urlAfterRedirects ?? this.router.url).split('?')[0];
    const parts = u.split('/').filter(Boolean);
    // Admin pages now live under /admin/<section>; portal pages under /portal/...
    const key = (parts[0] === 'admin' ? parts[1] : parts[0]) ?? 'dashboard';
    return TITLES[key] ?? { title: key, section: '' };
  });
}
