import React, { useRef, useEffect } from 'react';
import './ChartWidget.css';

const ChartWidget = ({ title, data, type = 'line', color = '#4f46e5' }) => {
  const canvasRef = useRef(null);

  useEffect(() => {
    drawChart();
  }, [data, type, color]);

  const drawChart = () => {
    const canvas = canvasRef.current;
    if (!canvas || !data || data.length === 0) return;

    const ctx = canvas.getContext('2d');
    const { width, height } = canvas;
    
    // 캔버스 클리어
    ctx.clearRect(0, 0, width, height);

    // 데이터 준비
    const values = data.map(d => d.value);
    const maxValue = Math.max(...values);
    const minValue = Math.min(...values);
    const padding = 40;
    const chartWidth = width - padding * 2;
    const chartHeight = height - padding * 2;

    // 스케일 계산
    const xStep = chartWidth / (data.length - 1);
    const valueRange = maxValue - minValue || 1;

    // 스타일 설정
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = 3;

    if (type === 'line') {
      drawLineChart(ctx, data, values, maxValue, minValue, valueRange, xStep, padding, chartWidth, chartHeight);
    } else if (type === 'bar') {
      drawBarChart(ctx, data, values, maxValue, minValue, valueRange, padding, chartWidth, chartHeight);
    } else if (type === 'area') {
      drawAreaChart(ctx, data, values, maxValue, minValue, valueRange, xStep, padding, chartWidth, chartHeight);
    }

    // 격자 그리기
    drawGrid(ctx, width, height, padding, chartWidth, chartHeight);
  };

  const drawLineChart = (ctx, data, values, maxValue, minValue, valueRange, xStep, padding, chartWidth, chartHeight) => {
    ctx.beginPath();
    data.forEach((point, index) => {
      const x = padding + index * xStep;
      const y = padding + chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
      
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();

    // 포인트 그리기
    ctx.fillStyle = color;
    data.forEach((point, index) => {
      const x = padding + index * xStep;
      const y = padding + chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
      
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fill();
    });
  };

  const drawBarChart = (ctx, data, values, maxValue, minValue, valueRange, padding, chartWidth, chartHeight) => {
    const barWidth = chartWidth / data.length * 0.8;
    const barSpacing = chartWidth / data.length * 0.2;

    ctx.fillStyle = color + '80'; // 반투명
    data.forEach((point, index) => {
      const x = padding + index * (barWidth + barSpacing) + barSpacing / 2;
      const barHeight = ((point.value - minValue) / valueRange) * chartHeight;
      const y = padding + chartHeight - barHeight;
      
      ctx.fillRect(x, y, barWidth, barHeight);
    });
  };

  const drawAreaChart = (ctx, data, values, maxValue, minValue, valueRange, xStep, padding, chartWidth, chartHeight) => {
    // 선 그리기
    ctx.beginPath();
    data.forEach((point, index) => {
      const x = padding + index * xStep;
      const y = padding + chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
      
      if (index === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();

    // 영역 채우기
    ctx.fillStyle = color + '20'; // 매우 반투명
    ctx.beginPath();
    ctx.moveTo(padding, padding + chartHeight);
    data.forEach((point, index) => {
      const x = padding + index * xStep;
      const y = padding + chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
      ctx.lineTo(x, y);
    });
    ctx.lineTo(padding + chartWidth, padding + chartHeight);
    ctx.closePath();
    ctx.fill();
  };

  const drawGrid = (ctx, width, height, padding, chartWidth, chartHeight) => {
    ctx.strokeStyle = '#e5e7eb';
    ctx.lineWidth = 1;

    // 수평선
    for (let i = 0; i <= 4; i++) {
      const y = padding + (chartHeight / 4) * i;
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(padding + chartWidth, y);
      ctx.stroke();
    }

    // 수직선
    for (let i = 0; i <= 6; i++) {
      const x = padding + (chartWidth / 6) * i;
      ctx.beginPath();
      ctx.moveTo(x, padding);
      ctx.lineTo(x, padding + chartHeight);
      ctx.stroke();
    }
  };

  return (
    <div className="chart-widget">
      <div className="chart-header">
        <h3>{title}</h3>
        <div className="chart-controls">
          <span className="chart-type">{type.toUpperCase()}</span>
        </div>
      </div>
      <div className="chart-container">
        <canvas 
          ref={canvasRef} 
          width={400} 
          height={200}
          className="chart-canvas"
        />
      </div>
    </div>
  );
};

export default ChartWidget;