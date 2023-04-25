import React, { useState, useEffect } from 'react';

function MobileAd(props) {
    const [isVisible, setIsVisible] = useState(true);

    useEffect(() => {
        const handleResize = () => {
            // 根据您的逻辑来设置 isVisible 状态
            setIsVisible(window.innerWidth <= 768); // 当页面宽度小于 768px 时，isVisible 为 false
        };

        window.addEventListener('resize', handleResize, false);

        return () => {
            window.removeEventListener('resize', handleResize, false);
        };
    }, []);

    return (
        <div>
            {isVisible && (
                <div className="wwads-cn wwads-horizontal" data-id="235" style={{ maxWidth: '350px' }}></div>
            )}
        </div>
    );
}

export default MobileAd;
