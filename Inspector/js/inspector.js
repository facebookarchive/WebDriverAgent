/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import React from 'react';

require('css/inspector.css');

function boolToString(boolValue) {
  return boolValue === '1' ? 'Yes' : 'No';
}

class Inspector extends React.Component {
  render() {
    return (
      <div id="inspector" className="section third">
        <div className="section-caption">
          Inspector
        </div>
        <div className="section-content-container">
          <div className="section-content">
            {this.renderInspector()}
          </div>
        </div>
      </div>
    );
  }

  renderInspector() {
    if (this.props.selectedNode == null) {
      return null;
    }

    const attributes = this.props.selectedNode.attributes;
    return (
      <div>
        {this.renderField('Class', attributes.type)}
        {this.renderField('Raw identifier', attributes.rawIdentifier)}
        {this.renderField('Name', attributes.name)}
        {this.renderField('Value', attributes.value)}
        {this.renderField('Label', attributes.label)}
        {this.renderField('Rect', attributes.rect)}
        {this.renderField('isEnabled', boolToString(attributes.isEnabled))}
        {this.renderField('isVisible', boolToString(attributes.isVisible))}
      </div>
    );
  }

  renderField(fieldName, fieldValue) {
    if (fieldValue == null) {
      return null;
    }
    return (
      <div className="inspector-field">
        <div className="inspector-field-caption">
          {fieldName}:
        </div>
        <div className="inspector-field-value">
          {String(fieldValue)}
        </div>
      </div>
    );
  }
}

Inspector.propTypes = {
  selectedNode: React.PropTypes.object,
};

module.exports = Inspector;
