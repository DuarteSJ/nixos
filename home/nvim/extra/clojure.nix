{ config, pkgs, ... }: {
    programs.nvf.settings.vim = {
        # Enable Clojure language support
        languages.clojure = {
            enable = true;
            treesitter.enable = true;
            lsp.enable = true;
        };
        extraPlugins = {
            # Conjure for REPL integration
            conjure = {
                package = pkgs.vimPlugins.conjure;
                setup = ''
                    -- Conjure configuration
                    vim.g["conjure#mapping#doc_word"] = "K"
                    vim.g["conjure#log#hud#width"] = 0.42
                    vim.g["conjure#log#hud#enabled"] = true
                    vim.g["conjure#log#hud#anchor"] = "SE"

                    -- Auto-repl setup for Clojure CLI
                    vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = true
                    vim.g["conjure#client#clojure#nrepl#connection#auto_repl#hidden"] = true
                    vim.g["conjure#client#clojure#nrepl#connection#auto_repl#cmd"] = "clojure"
                    vim.g["conjure#client#clojure#nrepl#eval#auto_require"] = false
                '';
            };
            # Structural editing for S-expressions
            vim-sexp = {
                package = pkgs.vimPlugins.vim-sexp;
            };
            # More intuitive keybindings for vim-sexp
            vim-sexp-mappings = {
                package = pkgs.vimPlugins.vim-sexp-mappings-for-regular-people;
            };
            # Rainbow delimiters for matching parens
            rainbow-delimiters = {
                package = pkgs.vimPlugins.rainbow-delimiters-nvim;
                setup = ''
                    require('rainbow-delimiters.setup').setup()
                '';
            };
        };
        # Clojure-specific keymaps
        keymaps = [
            # Conjure evaluation mappings
            {
                mode = "n";
                key = "<localleader>eb";
                action = "<cmd>ConjureEvalBuf<CR>";
            }
            {
                mode = "n";
                key = "<localleader>ee";
                action = "<cmd>ConjureEvalCurrentForm<CR>";
            }
            {
                mode = "n";
                key = "<localleader>er";
                action = "<cmd>ConjureEvalRootForm<CR>";
            }
            {
                mode = "v";
                key = "<localleader>E";
                action = "<cmd>ConjureEvalVisual<CR>";
            }
            # Conjure log management
            {
                mode = "n";
                key = "<localleader>lv";
                action = "<cmd>ConjureLogVSplit<CR>";
            }
            {
                mode = "n";
                key = "<localleader>lr";
                action = "<cmd>ConjureLogResetSoft<CR>";
            }
            # Documentation lookup
            {
                mode = "n";
                key = "<localleader>K";
                action = "<cmd>ConjureDocWord<CR>";
            }
            {
                mode = "n";
                key = "<localleader>rt";
                action = "<cmd>ConjureEval (let [tests (filter #(:test (meta %)) (vals (ns-interns *ns*))) passed (atom 0) failed (atom 0)] (println \"Running tests...\\n\") (doseq [v tests :let [test-name (:name (meta v)) test-fn (:test (meta v))]] (print \"Testing\" test-name \"... \") (flush) (let [result (atom {:pass 0 :fail 0 :error 0}) old-report clojure.test/report] (binding [clojure.test/report (fn [m] (case (:type m) :pass (swap! result update :pass inc) :fail (swap! result update :fail inc) :error (swap! result update :error inc) nil) (old-report m))] (try (test-fn) (catch Throwable e (swap! result update :error inc) (println \"Exception:\" e)))) (if (or (> (:fail @result) 0) (> (:error @result) 0)) (do (swap! failed inc) (println \"✗\")) (do (swap! passed inc) (println \"✓\"))))) (println \"\\n---\") (println \"Total:\" (count tests) \"tests,\" @passed \"passed,\" @failed \"failed\") (when (> @failed 0) (println \"\\n⚠️  Some tests failed! Check output above for details.\")))<CR>";
            }
        ];
    };
    # Ensure Clojure tools are available in the environment
    home.packages = with pkgs; [
        clojure          # Clojure CLI
        clojure-lsp      # LSP server
    ];
}
