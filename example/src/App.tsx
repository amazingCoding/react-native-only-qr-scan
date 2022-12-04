import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { openQRScan } from 'react-native-only-qr-scan';

export default function App() {
  const [result, setResult] = React.useState('')
  const getData = async () => {
    try {
      const data = await openQRScan("#08b89d", 'all', {
        title: '提示',
        content: '请打开相机权限',
        confirmText: '去设置',
        cancelText: '取消',
      });
      setResult(data);
      console.log(data);
    } catch (error) {
      console.log(error);
    }

  };

  return (
    <View style={styles.container}>
      <TouchableOpacity onPress={getData}>
        <Text style={{ color: "#ff00ff" }}>扫码</Text>
      </TouchableOpacity>
      <Text style={{ color: "#ff00ff" }}>Result: {result}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
