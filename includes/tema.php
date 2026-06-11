<?php
/**
 * Controle do tema visual (skin) do sistema.
 * Temas disponíveis: 'normal' (claro, padrão), 'escuro' (modo escuro) e 'eva' (NERV/Evangelion).
 */

const TEMAS_VALIDOS = ['normal', 'escuro', 'eva'];

function getTema(): string {
    $tema = $_COOKIE['tema'] ?? 'normal';
    return in_array($tema, TEMAS_VALIDOS, true) ? $tema : 'normal';
}

function setTema(string $tema): void {
    $tema = in_array($tema, TEMAS_VALIDOS, true) ? $tema : 'normal';
    setcookie('tema', $tema, time() + 60 * 60 * 24 * 365, '/');
    $_COOKIE['tema'] = $tema;
}

/**
 * Retorna 'dark' ou 'light' para o atributo data-bs-theme do Bootstrap,
 * que ajusta automaticamente componentes como modais, dropdowns e formulários.
 */
function getBsTheme(): string {
    return getTema() === 'normal' ? 'light' : 'dark';
}
