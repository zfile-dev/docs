import React, {useState, useRef, useEffect} from 'react';

function ComputeCommand() {
    const [value, setValue] = useState('/www/wwwroot/demo.zfile.vip');
    const [result, setResult] = useState('');

    const inputRef = useRef(null);

    useEffect(() => {
        handleCalculate();
    }, []);

    const handleCalculate = () => {
        // 如果 value 尾缀包含 /zfile-launch 则去除
        let path = value.trim();
        if (value.endsWith('/zfile-launch')) {
            path = value.substring(0, value.length - 13);
        }
        path = path || '/www/wwwroot/demo.zfile.vip'; // 如果输入框为空，则使用默认值
        const command = `${path}/zfile-launch ${path}/jre/bin/java -jar ${path}/zfile-pro-release.xjar --spring.config.location=file:${path}/application.properties`; // 根据路径计算命令
        setResult(command); // 将计算出的命令设置为计算结果
    };


    const handleCopy = () => {
        inputRef.current.select();
        document.execCommand('copy');
    };

    return (
        <div style={{ marginBottom: '20px' }}>
            <div style={{ display: 'flex', height: '40px', marginBottom: '3px' }}>
                <input type="text"
                       value={value}
                       onChange={(e) => setValue(e.target.value)}
                       className={'z-input'}
                       placeholder="请输入解压路径"/>
                <button className={'z-button'} onClick={handleCalculate}>生成执行命令</button>
            </div>
            <div style={{ display: 'flex' }}>
                <textarea rows="5"
                          className={'z-textarea'} value={result} ref={inputRef} readOnly />
                <button className={'z-button'} onClick={handleCopy}>复制执行命令</button>
            </div>
        </div>
    );
}

export default ComputeCommand;
