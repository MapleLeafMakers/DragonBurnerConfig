<template>
  <q-page>
    <div class="row q-col-gutter-md q-pa-xl justify-center">
      <div class="col-xs-12 col-md-6 relative-position">
        <div
          :class="{ hidden: modelLoaded }"
          style="
            color: grey;
            height: 375px;
            position: absolute;
            top: 16px;
            left: 16px;
            bottom: 0px;
            right: 0px;
            display: flex;
            flex-direction: row;
            justify-content: center;
          "
        >
          <div
            style="
              display: flex;
              flex-direction: column;
              justify-content: center;
            "
          >
            <q-spinner-hourglass size="250px" color="grey" />
            Loading the model, this may take a moment...
          </div>
        </div>
        <div
          ref="viewerContainer"
          class="online_3d_viewer"
          style="height: 375px; opacity: 0"
        ></div>
        <q-btn
          fab-mini
          class="bg-grey-1"
          icon="mdi-palette"
          style="position: absolute; top: 24px; left: 24px"
          ><q-menu>
            <q-color
              :model-value="rgbToHex(modelColor)"
              @update:model-value="onUpdateModelColor"
              no-header
              no-footer
            />
          </q-menu>
        </q-btn>
      </div>
      <div class="col-xs-12 col-md-6">
        <q-select
          emit-value
          v-model="extruder"
          :options="extruder_options"
          label="Extruder"
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          emit-value
          v-model="hotend"
          :options="hotend_options"
          label="Hotend"
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="probe"
          :options="
            Object.keys(info.universal.probe_options).filter((k) => !!k)
          "
          label="Probe (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="nozzle_led"
          :options="
            Object.keys(info.universal.nozzle_led_options).filter((k) => !!k)
          "
          label="Nozzle LEDs (optional)"
          clearable
          @update:model-value="onOptionsUpdate"
        />
        <q-select
          v-model="logo_led"
          :options="
            Object.keys(info.universal.logo_led_options).filter((k) => !!k)
          "
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
      </div>
    </div>
    <div class="row justify-center">
      <q-btn
        :disable="!canSubmit"
        color="primary"
        icon="download"
        label="Download STL Files"
        @click="download"
      />
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import * as OV from 'online-3d-viewer';
import * as THREE from 'three';

import info from 'src/v7.json';
import axios from 'axios';
import JSZip from 'jszip';

import { colors } from 'quasar';
const { rgbToHex, hexToRgb } = colors;

const extruder = ref<string>();
const hotend = ref<string>();
const probe = ref<string>('');
const nozzle_led = ref<string>('');
const logo_led = ref<string>('');

let defaultColor: { r: number; g: number; b: number } = { r: 142, g: 41, b: 0 };
try {
  defaultColor = JSON.parse(localStorage.getItem('modelColor')) || defaultColor;
} catch (err) {
  // let 'er go
}

const modelColor = ref<{ r: number; g: number; b: number }>(defaultColor);

const adxl_mount = ref<boolean>(false);
const hotend_fan_size = ref<string>('30mm');
const modelLoaded = ref<boolean>(false);
const viewerContainer = ref();
let modelSource: any;
let render: OV.EmbeddedViewer;

const canSubmit = computed(() => {
  return extruder.value && hotend.value;
});

const onUpdateModelColor = (color: string) => {
  modelColor.value = hexToRgb(color);
  loadModel(recolorModelSrc(modelSource));
  localStorage.setItem('modelColor', JSON.stringify(modelColor.value));
};

const getMeshColor = (mesh: any) => {
  if (mesh.name.startsWith('[c]_')) {
    return [0.8, 0.8, 0.8];
  }

  if (
    ['4010 Blower Fan', '3010 Axial Fan', '2510 Axial Fan'].indexOf(
      mesh.name
    ) === -1
  ) {
    return [
      modelColor.value.r / 255,
      modelColor.value.g / 255,
      modelColor.value.b / 255,
    ];
  }
  return mesh.color;
};

const recolorModelSrc = (modelSrc: any) => {
  return {
    ...modelSrc,
    meshes: modelSrc.meshes.map((m) => ({
      ...m,
      color: getMeshColor(m),
    })),
  };
};

const loadModel = async (modelSrc) => {
  const [importResult, threeObject] = await new Promise<[OV.ImportResult, any]>(
    (resolve, reject) => {
      const importer = render.modelLoader.importer.importers.filter((i) =>
        i.CanImportExtension('step')
      )[0] as OV.ImporterOcct;
      importer.Clear();
      importer.name = 'DragonBurnerAssembly';
      importer.model = new OV.Model();
      importer.extension = 'step';
      importer.error = false;
      importer.message = null;
      importer.ResetContent();

      importer.ImportResultJson(modelSrc, () => {
        render.modelLoader.importer.model = importer.GetModel();
        let importResult = new OV.ImportResult();
        importResult.mainFile = 'DragonBurnerAssembly.step';
        importResult.model = importer.GetModel();
        importResult.upVector = importer.GetUpDirection();

        let params = new OV.ModelToThreeConversionParams();
        params.forceMediumpForMaterials =
          render.modelLoader.hasHighpDriverIssue;
        let output = new OV.ModelToThreeConversionOutput();
        OV.ConvertModelToThreeObject(importResult.model, params, output, {
          onTextureLoaded: () => {
            render.GetViewer().Render();
          },
          onModelLoaded: (threeObject: THREE.Object3D) => {
            render.modelLoader.defaultMaterial = output.defaultMaterial;
            if (importResult.upVector === OV.Direction.X) {
              let rotation = new THREE.Quaternion().setFromAxisAngle(
                new THREE.Vector3(0.0, 0.0, 1.0),
                Math.PI / 2.0
              );
              threeObject.quaternion.multiply(rotation);
            } else if (importResult.upVector === OV.Direction.Z) {
              let rotation = new THREE.Quaternion().setFromAxisAngle(
                new THREE.Vector3(1.0, 0.0, 0.0),
                -Math.PI / 2.0
              );
              threeObject.quaternion.multiply(rotation);
            }
            resolve([importResult, threeObject]);
          },
        });
      });
    }
  );
  render.GetViewer().SetMainObject(threeObject);
  let boundingSphere = render.viewer.GetBoundingSphere(() => {
    return true;
  });
  render.viewer.AdjustClippingPlanesToSphere(boundingSphere);
  if (render.parameters.camera) {
    render.viewer.SetCamera(render.parameters.camera);
  } else {
    render.viewer.SetUpVector(OV.Direction.Y, false);
    render.viewer.FitSphereToWindow(boundingSphere, false);
  }

  render.model = importResult.model;
  if (render.parameters.onModelLoaded) {
    render.parameters.onModelLoaded();
  }
};

onMounted(() => {
  OV.SetExternalLibLocation('libs');
  // init all viewers on the page
  const el = document.querySelector('.online_3d_viewer');
  render = new OV.EmbeddedViewer(el as HTMLElement, {
    camera: new OV.Camera(
      new OV.Coord3D(40, -120, 0),
      new OV.Coord3D(0, 0, 0),
      new OV.Coord3D(0, 0, 1),
      45
    ),
    backgroundColor: new OV.RGBAColor(0, 0, 0, 0),
    onModelLoaded: () => {
      modelLoaded.value = true;
      viewerContainer.value.style.opacity = 1;
      onOptionsUpdate();
    },
  });
  axios.get('DragonBurnerAssembly.json').then((response) => {
    modelSource = response.data;
    loadModel(recolorModelSrc(modelSource));
  });
});

const hotend_options = computed(() => {
  const db = info['Dragon Burner'];

  let disabledOptions = [] as string[];
  if (extruder.value && db.extruder_options[extruder.value].hotend_options) {
    disabledOptions = Object.keys(db.hotend_options).filter((k) => {
      return !db.extruder_options[extruder.value].hotend_options.hasOwnProperty(
        k
      );
    });
  }
  return Object.entries(db.hotend_options).map(([key, value]) => {
    return {
      value: key,
      label: key,
      disable: disabledOptions.indexOf(key) !== -1,
    };
  });
});

const onOptionsUpdate = () => {
  if (!modelLoaded.value) return;
  let stl_files = stlFiles.value;
  const always_components = [
    '4010 Blower Fan',
    hotend_fan_size.value === '30mm' ? '3010 Axial Fan' : '2510 Axial Fan',
  ];
  let visible_components = stl_files.map((stl) =>
    stl.replace(/\.stl$/i, '').replaceAll('/', '__')
  );

  render.GetViewer().mainModel.EnumerateMeshes((mesh) => {
    const show =
      visible_components.indexOf(mesh.name) !== -1 ||
      always_components.indexOf(mesh.name) !== -1;
    mesh.visible = show;
  });

  render.GetViewer().Render();
};

const extruder_options = computed(() => {
  const db = info['Dragon Burner'];
  return Object.entries(db.extruder_options).map(
    ([extruder_name, extruder_opts]) => ({
      value: extruder_name,
      label: extruder_name,
      disable:
        hotend.value &&
        extruder_opts?.hotend_options &&
        !extruder_opts.hotend_options.hasOwnProperty(hotend.value),
    })
  );
});
const toArray = (val: string | string[]) => {
  if (Array.isArray(val)) {
    return val;
  }
  return [val];
};

const stlFiles = computed(() => {
  const files = [];
  const extruder_info = info['Dragon Burner'].extruder_options[extruder.value];

  if (extruder_info?.stl) {
    files.push(...toArray(extruder_info.stl));
  } else if (extruder_info) {
    files.push(...toArray(extruder_info));
  }
  let hotends: { [key: string]: string | string[] };
  if (extruder_info?.hotend_options) {
    hotends = extruder_info.hotend_options;
  } else {
    hotends = info['Dragon Burner'].hotend_options;
  }
  files.push(...toArray(hotends[hotend.value] || []));
  files.push(
    ...toArray(info.universal.nozzle_led_options[nozzle_led.value || ''])
  );
  files.push(...toArray(info.universal.logo_led_options[logo_led.value || '']));
  files.push(...toArray(info.universal.probe_options[probe.value || '']));
  if (adxl_mount.value) {
    files.push(...toArray(info.universal.adxl_mount['ADXL Mount']));
  }
  if (hotend_fan_size.value === '25mm') {
    files.push('2510_Spacer.stl');
  }
  return files;
});

const download = async () => {
  let stl_files = stlFiles.value;
  const zip = new JSZip();

  for (let f of stl_files) {
    const fileUrl = `https://raw.githubusercontent.com/chirpy2605/voron/main/V0/Dragon_Burner/STLs/v0.2/${f}`;
    const content = (await axios.get(fileUrl, { responseType: 'arraybuffer' }))
      .data;
    const baseName = f.indexOf('/') === -1 ? f : f.split('/')[1];
    zip.file(baseName, content, { binary: true });
  }
  const zipFile = await zip.generateAsync({ type: 'blob' });
  const link = document.createElement('a');
  link.download = 'Dragon_Burner_v7.zip';
  link.href = URL.createObjectURL(zipFile);
  link.click();
  URL.revokeObjectURL(link.href);
};
</script>
