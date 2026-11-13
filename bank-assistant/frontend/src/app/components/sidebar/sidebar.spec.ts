import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { describe, it, expect, beforeEach } from 'vitest';
import { SidebarComponent } from './sidebar';
import { AuthService, User } from '../../services/auth.service';

describe('SidebarComponent', () => {
  let fixture: ComponentFixture<SidebarComponent>;
  let currentUser$: BehaviorSubject<User | null>;
  let authStub: Partial<AuthService>;

  beforeEach(async () => {
    currentUser$ = new BehaviorSubject<User | null>({
      id: 1,
      email: 'admin@albaraka.tn',
      roles: ['SUPER_ADMIN'],
      permissions: ['RAGLAB_CONSOLE_VIEW', 'RAGLAB_CONSOLE_RUN', 'RAGLAB_CONSOLE_MANAGE'],
    } as User);

    authStub = {
      currentUser$: currentUser$.asObservable(),
      hasRole: (role: string) => role === 'SUPER_ADMIN',
      hasPermission: () => true,
      isStaff: () => true,
      isLegacyStaff: () => true,
      getAccessToken: () => 'fake-token',
      logout: () => {},
    };

    await TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, SidebarComponent],
      providers: [
        provideRouter([]),
        { provide: AuthService, useValue: authStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(SidebarComponent);
    fixture.detectChanges();
  });

  it('removes Connaissance, Faits gouvernés, and Taxonomie & catalogue while keeping Actualités under Administration', () => {
    const el = fixture.nativeElement as HTMLElement;
    const text = el.textContent ?? '';

    expect(text).not.toContain('Connaissance');
    expect(text).not.toContain('Faits gouvernés');
    expect(text).not.toContain('Taxonomie & catalogue');
    expect(text).toContain('Administration');
    expect(text).toContain('Actualités');

    const newsLink = el.querySelector('a[href="/admin/news"]');
    expect(newsLink).not.toBeNull();

    const brandImg = el.querySelector('img.brand-mark') as HTMLImageElement | null;
    expect(brandImg?.getAttribute('src')).toBe('/logo.png');
  });
});
