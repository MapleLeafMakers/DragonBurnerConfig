const fs = require('fs');
const occtimportjs = require('occt-import-js')();

occtimportjs.then((occt) => {
  let fileUrl = process.argv[2];
  let fileContent = fs.readFileSync(fileUrl);
  let result = occt.ReadStepFile(fileContent, null);

  process.stdout.write(JSON.stringify(result));
});
