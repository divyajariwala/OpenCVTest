/**
 * @format
 */

import {AppRegistry} from "react-native";
import App from './App';
import {name as appName} from './app.json';

// Native Module tests
import {NativeModules, Platform} from "react-native";
let {RNSKOpenCVModule} = NativeModules // --> RNSKOpenCVModule.java
// console.warn("RNSKOpenCVModule exists: " + (JSON.stringify(!!RNSKOpenCVModule)))

// success
false && RNSKOpenCVModule.test(Platform.OS)
.then((result) => console.warn (`RNSKOpenCVModule.test(${Platform.OS}) result: ` + JSON.stringify(result, null, 2)))
.catch(console.error)

// error
RNSKOpenCVModule.testWithString(Platform.OS)
.then((result) => console.warn (`RNSKOpenCVModule.testWithString(${Platform.OS}) result: ` + JSON.stringify(result, null, 2)))
.catch(console.error)

AppRegistry.registerComponent(appName, () => App);
