<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-toolbar-title> Dragon Burner v7 Configurator (beta)</q-toolbar-title>
        <q-space />
        <q-btn
          flat
          round
          icon="mdi-leaf-maple"
          size="md"
          href="https://github.com/https://github.com/MapleLeafMakers"
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
          <q-tooltip>View on GitHub</q-tooltip>
        </q-btn>
      </q-toolbar>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts"></script>
