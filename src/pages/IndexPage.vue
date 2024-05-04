<template>
  <q-page>
    <div class="row q-col-gutter-md q-pa-xl justify-center">
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
          :options="info.probes"
          label="Probe (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />

        <q-select
          v-model="nozzle_leds"
          :options="info.nozzle_leds"
          label="Nozzle LEDs (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />

        <q-select
          v-model="logo_led"
          :options="info.logo_led"
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

        <q-select
          v-model="logo"
          label="Logo"
          :options="info.logos"
          @update:model-value="onOptionsUpdate"
        />

        <q-select
          v-model="rear_brace"
          label="Rear Brace (Optional)"
          :options="info.rear_braces"
          @update:model-value="onOptionsUpdate"
          clearable
        />

        <q-select
          v-model="adxl_mount"
          label="ADXL Mount (optional)"
          clearable
          :options="Object.keys(info.adxl_mounts)"
          @update:model-value="onOptionsUpdate"
        />

        <q-option-group
          :options="[
            { label: 'Googly Eyes', value: 'googly_eyes' },
            { label: 'Cat Ears', value: 'cat_ears' },
          ]"
          type="checkbox"
          v-model="extras"
          @update:model-value="onOptionsUpdate"
        />
      </div>
      <div class="col-xs-12 col-md-6">
        <q-list bordered separator>
          <q-item clickable v-ripple v-for="stl in stlFiles" :key="stl">
            <q-item-section>{{ stl }}</q-item-section>
          </q-item>
        </q-list>

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
import { ref, computed, reactive } from 'vue';

import info from 'src/v8.json';
// import axios from 'axios';
import JSZip from 'jszip';
import axios from 'axios';

const extruder = ref<string>();
const hotend = ref<string>();
const probe = ref<string>();
const nozzle_leds = ref<string>();
const logo_led = ref<string>();
const logo = ref<string>(info.logos[0]);
const adxl_mount = ref<string>();
const hotend_fan_size = ref<string>('30mm');
const rear_brace = ref<string>();

const extras = ref<string[]>([]);
const complete = ref<boolean>(false);

const stlFiles = ref<string[]>([]);

const canSubmit = computed(() => {
  return true;
});

const stlExists = (f: string) => {
  return info.files.indexOf(f) != -1;
};

const onOptionsUpdate = () => {
  stlFiles.value = [];

  console.log({
    extruder: extruder.value,
    hotend: hotend.value,
    probe: probe.value,
    nozzle_leds: nozzle_leds.value,
    logo_led: logo_led.value,
    logo: logo.value,
    adxl_mount: adxl_mount.value,
    hotend_fan_size: hotend_fan_size.value,
    extras: extras.value,
  });

  complete.value = true;

  if (extruder.value && hotend.value) {
    const extruderInfo = info.extruders[extruder.value];
    stlFiles.value.push(extruderInfo.extruder_mount);
    const selectedHotendFiles = Array.isArray(info.hotends[hotend.value])
      ? info.hotends[hotend.value]
      : [info.hotends[hotend.value]];

    stlFiles.value.push(
      ...selectedHotendFiles.map((f) => extruderInfo.hotend_mounts + f)
    );
  } else {
    complete.value = false;
  }

  if (logo.value) {
    const cat_ears = extras.value.indexOf('cat_ears') != -1;
    const cowlFile = `Cowls/${logo.value}/${cat_ears ? 'Cat_Cowls/' : ''}Cowl_${
      probe.value ? probe.value : 'NoProbe'
    }.stl`;
    const diffuserFile = `Cowls/${logo.value}/[c]_${logo.value}_Diffuser.stl`;
    stlFiles.value.push(cowlFile);
    stlFiles.value.push(diffuserFile);
  } else {
    complete.value = false;
  }

  if (nozzle_leds.value) {
    stlFiles.value.push(`${nozzle_leds.value}_Mount.stl`);
    stlFiles.value.push(`${nozzle_leds.value}_Soldering_Jig.stl`);
  }

  if (logo_led.value) {
    stlFiles.value.push(`[o]_Carrier_${logo_led.value}.stl`);
  }

  if (adxl_mount.value) {
    stlFiles.value.push(info.adxl_mounts[adxl_mount.value]);
  }

  if (extras.value.indexOf('googly_eyes') != -1) {
    stlFiles.value.push('GooglyEyeInsert_x2.stl');
  }

  if (hotend_fan_size.value == '25mm') {
    stlFiles.value.push('2510_Spacer.stl');
  }

  if (rear_brace.value) {
    stlFiles.value.push(`Brace_${rear_brace.value}.stl`);
  }

  console.log(stlFiles);
  console.assert(stlFiles.value.every(stlExists));
};

const download = async () => {
  const zip = new JSZip();

  for (let f of stlFiles.value) {
    const fileUrl = `https://raw.githubusercontent.com/chirpy2605/voron/main/V0/Dragon_Burner/STLs/v0.2/${f}`;
    const content = (await axios.get(fileUrl, { responseType: 'arraybuffer' }))
      .data;
    const baseName = f.split('/').reverse()[0];
    zip.file(baseName, content, { binary: true });
  }
  const zipFile = await zip.generateAsync({ type: 'blob' });
  const link = document.createElement('a');
  link.download = 'Dragon_Burner_v8.zip';
  link.href = URL.createObjectURL(zipFile);
  link.click();
  URL.revokeObjectURL(link.href);
};
</script>
