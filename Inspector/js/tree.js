/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import PropTypes from 'prop-types';
import React from 'react';
import TreeView from 'react-treeview';

import classNames from 'classnames';

require('css/tree.css');
require('react-treeview/react-treeview.css');

const CAPTION_HEIGHT = 100;
const CAPTION_PADDING = 20;

class Tree extends React.Component {
  render() {
    const style = this.styleWithMaxHeight(
      this.maxTreeHeight());
    return (
      <div id="tree" className="section second">
        <div className="section-caption">
          Tree of Elements
        </div>
        <div className="section-content-container">
          <div className="section-content">
            <div className="tree-container" style={style}>
              {this.renderTree()}
            </div>
          </div>
        </div>
      </div>
    );
  }

  maxTreeHeight() {
    return window.innerHeight - CAPTION_HEIGHT + CAPTION_PADDING;
  }

  styleWithMaxHeight(height) {
    return {
      'maxHeight': height,
    };
  }

  renderTree() {
    if (this.props.rootNode == null) {
      return null;
    }
    return (
      <div>
        <div className="tree-header"/>
        {this.renderNode(this.props.rootNode)}
      </div>
    );
  }

  renderNode(node) {
    const isSelected = (this.props.selectedNode != null
      && this.props.selectedNode.key === node.key);
    const className = classNames(
      'tree-node',
      {
        'selected' : isSelected,
      }
    );

    const nodeLabelView = (
      <span
        className={className}
        onClick={(event) => this.onNodeClick(node)}
        onMouseEnter={(event) => this.onNodeMouseEnter(node)}
        onMouseLeave={(event) => this.onNodeMouseLeave(node)}>
        {node.name}
      </span>
    );

    var childrenViews = null;
    if (node.children != null) {
      childrenViews = node.children.map((child) => {
        return this.renderNode(child);
      });
    }

    return (
      <TreeView
        key={node.key}
        nodeLabel={nodeLabelView}
        defaultCollapsed={false}>
        {childrenViews}
      </TreeView>
    );
  }

  onNodeClick(node) {
    if (this.props.onSelectedNodeChange != null) {
      this.props.onSelectedNodeChange(node);
    }
  }

  onNodeMouseEnter(node) {
    if (this.props.onHighlightedNodeChange != null) {
      this.props.onHighlightedNodeChange(node);
    }
  }

  onNodeMouseLeave(node) {
    if (this.props.onHighlightedNodeChange != null) {
      this.props.onHighlightedNodeChange(null);
    }
  }
}

Tree.propTypes = {
  onSelectedNodeChange: PropTypes.func,
  onHighlightedNodeChange: PropTypes.func,
  rootNode: PropTypes.object,
  selectedNode: PropTypes.object,
};

module.exports = Tree;
