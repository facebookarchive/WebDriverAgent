import PropTypes from "prop-types";
import React from "react";

import HTTP from "js/http";

require("css/device.css");

class DeviceList extends React.Component {
  constructor() {
    super();
    this.state = {
      connectedDevice: []
    };
  }
  updateAvailableDevices() {
    HTTP.getConnectedDevices((data) => {
      this.setState({
        connectedDevice: data
      });
    });
  }
  componentDidMount() {
    this.updateAvailableDevices();
    HTTP.onNewDeviceConnected((data) => {
      const connectedDevices = this.state.connectedDevice;
      connectedDevices.push(data);
      this.setState({
        connectedDevice: connectedDevices
      });
    });

    HTTP.onDeviceDisconnected((data) => {
      this.updateAvailableDevices();
    });

    HTTP.onDeviceUnBlock((deviceData) => {
        const deviceId = deviceData.deviceMeta.deviceId;
        this.state.connectedDevice.forEach((device) => {
            if(device.deviceMeta.deviceId == deviceId) {
                device.isBlocked = false;
            }
        });

        this.setState({
            connectedDevice: this.state.connectedDevice
        })
    })


    HTTP.onDeviceBlock((deviceData) => {
        const deviceId = deviceData.deviceMeta.deviceId;
        this.state.connectedDevice.forEach((device) => {
            if(device.deviceMeta.deviceId == deviceId) {
                device.isBlocked = true;
            }
        });

        this.setState({
            connectedDevice: this.state.connectedDevice
        })
    })
  }

  onDeviceSelected(ev, device) {
    if (device.isBlocked) {
      return;
    }
    if (this.props.onDeviceSelected) {
      this.props.onDeviceSelected(device);
    }
  }

  render() {
    if (this.state.connectedDevice.length > 0) {
      return (
        <div className="device-list-container">
          <h2> Connected Devices </h2>
          <ul className="device-list">
            {this.state.connectedDevice.map(device => {
              return (
                <li
                  className={device.isBlocked ? "blocked" : ""}
                  key={device.deviceMeta.deviceId}
                  onClick={ev => this.onDeviceSelected(ev, device)}
                >
                  <img src="/assets/IPhone_5.png" className="device-img" />
                  <div className="device-desc">
                    {device.deviceMeta.deviceModel +
                      "-" +
                      device.deviceMeta.osVersion}
                  </div>
                </li>
              );
            })}
          </ul>
        </div>
      );
    } else {
      return <div className ="no-device"> <p>No Device connected </p></div>;
    }
  }
}

module.exports = DeviceList;
