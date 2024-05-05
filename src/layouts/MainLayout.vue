<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-toolbar-title>
          <div class="flex">
            <img src="icons/favicon-32x32.png" class="header-icon" />
            <div class="q-ml-sm">Dragon Burner v8 Configurator</div>
          </div>
        </q-toolbar-title>
        <q-space />
        <q-btn
          flat
          round
          icon="mdi-leaf-maple"
          size="md"
          href="https://github.com/MapleLeafMakers"
          target="_blank"
        >
          <q-tooltip>Made by Maple Leaf Makers</q-tooltip>
        </q-btn>
        <q-btn
          flat
          round
          icon="mdi-github"
          size="md"
          href="https://github.com/chirpy2605/voron/tree/main/V0/Dragon_Burner"
          target="_blank"
        >
          <q-tooltip>Dragon Burner Repo</q-tooltip>
        </q-btn>
      </q-toolbar>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts"></script>
