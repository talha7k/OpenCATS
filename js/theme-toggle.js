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
            button.type = 'button';
            button.className = 'linkButton';
            button.innerHTML = '🌙';
            button.title = 'Toggle dark/light mode';
            
            // Find the logout form to insert before it
            var logoutForm = document.getElementById('logoutForm');
            if (logoutForm && logoutForm.parentNode) {
                // Insert before the logout form
                logoutForm.parentNode.insertBefore(button, logoutForm);
                
                // Add separator
                var separator = document.createTextNode(' ');
                logoutForm.parentNode.insertBefore(separator, logoutForm);
            } else {
                // Fallback: add to header block
                var headerBlock = document.getElementById('headerBlock');
                if (headerBlock) {
                    headerBlock.appendChild(button);
                } else {
                    // Last resort: fixed position but smaller
                    button.style.cssText = 'position:fixed;top:10px;right:10px;z-index:9999;';
                    document.body.appendChild(button);
                }
            }
            
            return button;
        },

        bindEvents: function() {
            var button = document.getElementById('theme-toggle');
            if (button) {
                button.addEventListener('click', this.toggleTheme.bind(this));
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
