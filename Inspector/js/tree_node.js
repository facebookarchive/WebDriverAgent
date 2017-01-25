/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

class TreeNode {
  static buildNode(node, context) {
    const key = context.buildUniqueNodeKey();
    const name = TreeNode.buildFullName(node);
    const children = TreeNode.buildChildren(node, context);
    return new TreeNode(key, name, children, node);
  }

  static buildFullName(node) {
    var fullName = '[' + node.type + ']';
    if (node.name != null) {
      fullName += ' - ' + node.name;
    }
    return fullName;
  }

  static buildChildren(node, context) {
    var children = null;
    if (node.children != null) {
      children = node.children.map((child) => {
        return TreeNode.buildNode(child, context);
      });
    }
    return children;
  }

  static buildRect(rect) {
    return {
      origin: {
        x: rect.x,
        y: rect.y,
      },
      size: {
        height: rect.height,
        width: rect.width,
      },
    };
  }

  constructor(key, name, children, node) {
    this.key = key;
    this.name = name;
    this.children = children;
    this.rect = TreeNode.buildRect(node.rect);
    this.attributes = {
      type: node.type,
      rawIdentifier: node.rawIdentifier,
      name: node.name,
      value: node.value,
      label: node.label,
      rect: node.frame,
      isEnabled: node.isEnabled,
      isVisible: node.isVisible,
    };
  }
}

module.exports = TreeNode;
