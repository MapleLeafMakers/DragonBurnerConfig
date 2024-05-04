<template>
  <q-page>
    <div class="row q-col-gutter-md q-pa-xl justify-center">
      <div class="col-xs-12 col-md-6 relative-position"></div>
      <div class="col-xs-12 col-md-6">
        <q-select
          emit-value
          v-model="extruder"
          :options="Object.keys(info.extruders)"
          label="Extruder"
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          emit-value
          v-model="hotend"
          :options="Object.keys(info.hotends)"
          label="Hotend"
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="probe"
          :options="Object.keys(info.probes)"
          label="Probe (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="nozzle_leds"
          :options="Object.keys(info.nozzle_leds)"
          label="Nozzle LEDs (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="logo_led"
          :options="Object.keys(info.logo_led)"
          label="Logo LED (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="hotend_fan_size"
          label="Hotend Fan"
          :options="['30mm', '25mm']"
          @update:model-value="onOptionsUpdate"
        />

        <q-checkbox
          label="Include ADXL Mount?"
          v-model="adxl_mount"
          @update:model-value="onOptionsUpdate"
        />
        <div class="q-mt-xl" style="text-align: center">
          <q-btn
            :disable="!canSubmit"
            color="primary"
            icon="download"
            label="Download STL Files"
            @click="download"
          />
        </div>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';

import info from 'src/v8.json';
// import axios from 'axios';
import JSZip from 'jszip';

const extruder = ref<string>();
const hotend = ref<string>();
const probe = ref<string>('');
const nozzle_leds = ref<string>('');
const logo_led = ref<string>('');

const adxl_mount = ref<boolean>(false);
const hotend_fan_size = ref<string>('30mm');

const canSubmit = computed(() => {
  return extruder.value && hotend.value;
});

const onOptionsUpdate = (e) => {
  console.log(e);
};

const download = async () => {
  const zip = new JSZip();

  // for (let f of stl_files) {
  //   const fileUrl = `https://raw.githubusercontent.com/chirpy2605/voron/main/V0/Dragon_Burner/STLs/v0.2/${f}`;
  //   const content = (await axios.get(fileUrl, { responseType: 'arraybuffer' }))
  //     .data;
  //   const baseName = f.indexOf('/') === -1 ? f : f.split('/')[1];
  //   zip.file(baseName, content, { binary: true });
  // }
  const zipFile = await zip.generateAsync({ type: 'blob' });
  const link = document.createElement('a');
  link.download = 'Dragon_Burner_v8.zip';
  link.href = URL.createObjectURL(zipFile);
  link.click();
  URL.revokeObjectURL(link.href);
};
</script>
