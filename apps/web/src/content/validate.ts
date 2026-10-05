import { buildPackBody } from "./load-pack";

const pack = buildPackBody();
console.log(
  JSON.stringify(
    {
      skills: pack.skills.length,
      lessons: pack.lessons.length,
      sha256: pack.sha256,
    },
    null,
    2,
  ),
);
