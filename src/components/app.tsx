import React from "react";
import { Text } from "./text";
import { useSampleText } from "../hooks/use-sample-text";
import Icon from "../assets/concord.png";

import "./app.scss";

declare const __webpack_public_path__: string;

export const App = () => {
  const sampleText = useSampleText();
  return (
    <div className="app">
      <img src={Icon}/>
      <Text text={sampleText} />
      <img src={`${__webpack_public_path__}images/happy-student.jpg`}/>
    </div>
  );
};
