#!/usr/bin/env node
"use strict";

const env = require("./lib/env.js");
const { apiRequest, expectSuccess } = require("./lib/http.js");
const { printJson } = require("./lib/output.js");

async function main() {
  let orgId = "";
  let customerId = "";

  let displayNameSet = false;
  let displayName = "";
  let cellPhoneSet = false;
  let cellPhone = "";
  let emailSet = false;
  let email = "";
  let birthdaySet = false;
  let birthday = "";
  let genderSet = false;
  let gender = "";
  let languageSet = false;
  let language = "";
  let nationSet = false;
  let nation = "";
  let locationSet = false;
  let location = "";
  let addressSet = false;
  let address = "";
  let aboutSet = false;
  let about = "";
  let customField1Set = false;
  let customField1 = "";
  let customField2Set = false;
  let customField2 = "";
  let customField3Set = false;
  let customField3 = "";

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--org-id":
        orgId = argv[++i] || "";
        break;
      case "--customer-id":
        customerId = argv[++i] || "";
        break;
      case "--display-name":
        displayNameSet = true;
        displayName = argv[++i] || "";
        break;
      case "--cell-phone":
        cellPhoneSet = true;
        cellPhone = argv[++i] || "";
        break;
      case "--email":
        emailSet = true;
        email = argv[++i] || "";
        break;
      case "--birthday":
        birthdaySet = true;
        birthday = argv[++i] || "";
        break;
      case "--gender":
        genderSet = true;
        gender = argv[++i] || "";
        break;
      case "--language":
        languageSet = true;
        language = argv[++i] || "";
        break;
      case "--nation":
        nationSet = true;
        nation = argv[++i] || "";
        break;
      case "--location":
        locationSet = true;
        location = argv[++i] || "";
        break;
      case "--address":
        addressSet = true;
        address = argv[++i] || "";
        break;
      case "--about":
        aboutSet = true;
        about = argv[++i] || "";
        break;
      case "--custom-field-1":
        customField1Set = true;
        customField1 = argv[++i] || "";
        break;
      case "--custom-field-2":
        customField2Set = true;
        customField2 = argv[++i] || "";
        break;
      case "--custom-field-3":
        customField3Set = true;
        customField3 = argv[++i] || "";
        break;
      default:
        process.stderr.write(`Unknown option: ${argv[i]}\n`);
        process.exit(1);
    }
  }

  if (!customerId) {
    process.stderr.write("Missing required option: --customer-id\n");
    process.exit(1);
  }

  if (
    !displayNameSet &&
    !cellPhoneSet &&
    !emailSet &&
    !birthdaySet &&
    !genderSet &&
    !languageSet &&
    !nationSet &&
    !locationSet &&
    !addressSet &&
    !aboutSet &&
    !customField1Set &&
    !customField2Set &&
    !customField3Set
  ) {
    process.stderr.write("Provide at least one update field.\n");
    process.exit(1);
  }

  env.requireRuntimeEnv();
  orgId = env.resolveOrgId(orgId);

  const body = { orgId };
  if (displayNameSet) body.displayName = displayName;
  if (cellPhoneSet) body.cellPhone = cellPhone;
  if (emailSet) body.email = email;
  if (birthdaySet) body.birthday = birthday;
  if (genderSet) body.gender = gender;
  if (languageSet) body.language = language;
  if (nationSet) body.nation = nation;
  if (locationSet) body.location = location;
  if (addressSet) body.address = address;
  if (aboutSet) body.about = about;
  if (customField1Set) body.customField1 = customField1;
  if (customField2Set) body.customField2 = customField2;
  if (customField3Set) body.customField3 = customField3;

  const query = env.buildQuery([["orgId", orgId]]);
  const result = await apiRequest(
    "PATCH",
    `/developer/v1/customers/${customerId}${query}`,
    body
  );
  expectSuccess(result);
  printJson(result.text);
}

main().catch((err) => {
  process.stderr.write(`${err && err.message ? err.message : err}\n`);
  process.exit(1);
});
