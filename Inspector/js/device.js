
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
      HTTP.on("getConnectedDevices",null,function(data){
          const connectedDevice = JSON.parse(data);
          this.setState({
              connectedDevice : connectedDevice
          })
      })
  }


  render() {
      if(this.state.connectedDevice.length > 0) {
        return (
            <div>
                <ul>
                    {
                        this.state.connectedDevice.map(function(device){
                            return <li key={device.deviceId}>device.deviceId</li>
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
