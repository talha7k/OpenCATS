(function() {
    'use strict';

    var ThemeToggle = {
        STORAGE_KEY: 'opencats-theme',
        THEMES: {
            LIGHT: 'light',
            DARK: 'dark'
        },

        init: function() {
            var savedTheme = localStorage.getItem(this.STORAGE_KEY);
            var systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            
            if (savedTheme) {
                this.setTheme(savedTheme);
            } else if (systemPrefersDark) {
                this.setTheme(this.THEMES.DARK);
            } else {
                this.setTheme(this.THEMES.LIGHT);
            }

            this.createToggleButton();
            this.bindEvents();
            
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
                if (!localStorage.getItem(this.STORAGE_KEY)) {
                    this.setTheme(e.matches ? this.THEMES.DARK : this.THEMES.LIGHT);
                }
            }.bind(this));
        },

        setTheme: function(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem(this.STORAGE_KEY, theme);
            this.updateToggleButton(theme);
        },

        toggleTheme: function() {
            var currentTheme = document.documentElement.getAttribute('data-theme') || this.THEMES.LIGHT;
            var newTheme = currentTheme === this.THEMES.DARK ? this.THEMES.LIGHT : this.THEMES.DARK;
            this.setTheme(newTheme);
        },

        updateToggleButton: function(theme) {
            var button = document.getElementById('theme-toggle');
            if (button) {
                var icon = theme === this.THEMES.DARK ? '☀️' : '🌙';
                button.innerHTML = icon;
                button.title = theme === this.THEMES.DARK ? 'Switch to light mode' : 'Switch to dark mode';
            }
        },

        createToggleButton: function() {
            var button = document.createElement('button');
            button.id = 'theme-toggle';
            button.className = 'theme-toggle';
            button.innerHTML = '🌙';
            button.title = 'Toggle dark/light mode';
            button.style.cssText = [
                'position: fixed',
                'top: 10px',
                'right: 10px',
                'z-index: 9999',
                'background: var(--bg-button)',
                'color: var(--color-text-white)',
                'border: 1px solid var(--border-color)',
                'border-radius: 4px',
                'padding: 8px 12px',
                'cursor: pointer',
                'font-size: 16px',
                'transition: background-color 0.3s ease'
            ].join(';');
            
            document.body.appendChild(button);
            return button;
        },

        bindEvents: function() {
            var button = document.getElementById('theme-toggle');
            if (button) {
                button.addEventListener('click', this.toggleTheme.bind(this));
                
                button.addEventListener('mouseenter', function() {
                    this.style.backgroundColor = 'var(--bg-button-hover)';
                });
                
                button.addEventListener('mouseleave', function() {
                    this.style.backgroundColor = 'var(--bg-button)';
                });
            }
        }
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            ThemeToggle.init();
        });
    } else {
        ThemeToggle.init();
    }
})();
