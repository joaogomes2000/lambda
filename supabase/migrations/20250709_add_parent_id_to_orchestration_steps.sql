-- Migration: Adiciona a coluna parent_id para suportar estrutura de árvore
ALTER TABLE orchestration_steps
ADD COLUMN parent_id integer REFERENCES orchestration_steps(id) ON DELETE CASCADE;
