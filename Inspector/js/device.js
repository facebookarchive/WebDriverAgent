
import PropTypes from 'prop-types';
import React from 'react';

import HTTP from 'js/http';

require('css/device.css');

class Device extends React.Component {
  constructor() {
    super();
    this.state = {
        connectedDevice:[]
    }
  }

  componentDidMount() {
      HTTP.emit("getConnectedDevices",null,(data) => {
          this.setState({
              connectedDevice : data
          })
      })
  }

  onDeviceSelected(ev, device) {
      if(this.props.onDeviceSelected) {
        this.props.onDeviceSelected(device);
      }
  }


  render() {
      if(this.state.connectedDevice.length > 0) {
        return (
            <div className="device-list-container">
                <ul className="device-list">
                    {
                        this.state.connectedDevice.map((device) => {
                            return <li key={device.deviceId} onClick={(ev) => this.onDeviceSelected(ev,device)}>{device.deviceModel + "-" + device.osVersion}</li>
                        })
                    }
                </ul>
            </div>
        );
      }
      else {
          return(<div> No Device connected</div>);
      }
    
  }

}


module.exports = Device;
