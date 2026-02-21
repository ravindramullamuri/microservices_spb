import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityUtils {
  // Add semantic labels to widgets
  static Widget addSemanticLabel(Widget widget, String label) {
    return Semantics(
      label: label,
      child: widget,
    );
  }

  // Add semantic labels to buttons
  static Widget addButtonSemantics(Widget button, String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: true,
      child: button,
    );
  }

  // Add semantic labels to text fields
  static Widget addTextFieldSemantics(Widget textField, String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      enabled: true,
      child: textField,
    );
  }

  // Add semantic labels to images
  static Widget addImageSemantics(Widget image, String label) {
    return Semantics(
      label: label,
      image: true,
      child: image,
    );
  }

  // Add semantic labels to links
  static Widget addLinkSemantics(Widget link, String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      link: true,
      enabled: true,
      child: link,
    );
  }

  // Add semantic labels to checkboxes
  static Widget addCheckboxSemantics(Widget checkbox, String label, bool checked) {
    return Semantics(
      label: label,
      checked: checked,
      enabled: true,
      child: checkbox,
    );
  }

  // Add semantic labels to radio buttons
  static Widget addRadioSemantics(Widget radio, String label, bool selected) {
    return Semantics(
      label: label,
      selected: selected,
      enabled: true,
      child: radio,
    );
  }

  // Add semantic labels to switches
  static Widget addSwitchSemantics(Widget switchWidget, String label, bool toggled) {
    return Semantics(
      label: label,
      toggled: toggled,
      enabled: true,
      child: switchWidget,
    );
  }

  // Add semantic labels to sliders
  static Widget addSliderSemantics(Widget slider, String label, double value, double min, double max) {
    return Semantics(
      label: label,
      value: '$value',
      increasedValue: '${value + ((max - min) / 10)}',
      decreasedValue: '${value - ((max - min) / 10)}',
      enabled: true,
      child: slider,
    );
  }

  // Add semantic labels to scrollable widgets
  static Widget addScrollableSemantics(Widget scrollable, String label) {
    return Semantics(
      label: label,
      child: scrollable,
      explicitChildNodes: true,
    );
  }



  // Add semantic labels to containers
  static Widget addContainerSemantics(Widget container, String label) {
    return Semantics(
      label: label,
      container: true,
      child: container,
    );
  }

  // Add semantic labels to headers
  static Widget addHeaderSemantics(Widget header, String label) {
    return Semantics(
      label: label,
      header: true,
      child: header,
    );
  }

  // Add semantic labels to lists
  static Widget addListSemantics(Widget list, String label) {
    return Semantics(
      label: label,
      explicitChildNodes: true,
      child: list,
    );
  }

  // Add semantic labels to list items
  static Widget addListItemSemantics(Widget listItem, String label, int index, int total) {
    return Semantics(
      label: label,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Item'): () {},
      },
      child: MergeSemantics(
        child: Semantics(
          value: 'Item $index of $total',
          child: listItem,
        ),
      ),
    );
  }
}
