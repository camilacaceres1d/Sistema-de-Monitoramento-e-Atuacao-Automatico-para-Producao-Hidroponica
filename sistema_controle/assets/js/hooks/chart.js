import * as echarts from "../../vendor/echarts.min.js"

export const Chart = {
  mounted() {
    this.chart = echarts.init(this.el)

    this.handleEvent(`chart-update-${this.el.id}`, (payload) => {
      const currentOption = this.chart.getOption()
      this.parseFunctions(payload)

      if (currentOption && payload.legend && payload.legend.selected) {
        delete payload.legend.selected
      }

      this.chart.setOption(payload)
    })

    this.resizeHandler = () => {
      this.chart.resize()
    }
    window.addEventListener('resize', this.resizeHandler)
  },

  parseFunctions(obj) {
    if (!obj || typeof obj !== 'object') return

    for (const key in obj) {
      if (typeof obj[key] === 'string' && obj[key].startsWith('function(')) {
        try {
          obj[key] = eval(`(${obj[key]})`)
        } catch (e) {
        }
      } else if (typeof obj[key] === 'object') {
        this.parseFunctions(obj[key])
      }
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.dispose()
    }
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
  }
}
