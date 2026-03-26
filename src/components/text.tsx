import React from "react";

interface IProps {
  text: string;
}

export const Text: React.FC<IProps> = ({ text }) => (
  <h1>{ text }</h1>
);
