import { types } from "mobx-state-tree";
import { SectionModel } from "./section";

export const ProblemModel = types
  .model("Problem", {
    ordinal: types.integer,
    title: types.string,
    subtitle: "",
    sections: types.array(SectionModel)
  })
  .views((self) => {
    return {
      get fullTitle() {
        return `${self.title}${self.subtitle ? `: ${self.subtitle}` : ""}`;
      },
    };
  });

export type ProblemModelType = typeof ProblemModel.Type;
