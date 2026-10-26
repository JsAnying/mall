import { beforeEach, describe, expect, it, vi } from 'vitest'
import axios from 'axios'

vi.mock('element-plus', () => ({ ElMessage: { error: vi.fn() } }))
import { ElMessage } from 'element-plus'
import request, { setUnauthorizedHandler } from './request.js'
import { safeRedirect } from './auth.js'

function responseAdapter(data) {
  return async (config) => ({ config, data, status: 200, statusText: 'OK', headers: {} })
}
function failureAdapter(status, data = {}) {
  return async (config) => {
    throw new axios.AxiosError('failed', 'ERR_BAD_RESPONSE', config, null, { status, data, config })
  }
}

beforeEach(() => {
  vi.stubGlobal('localStorage', { getItem: vi.fn(() => 'test-token') })
  setUnauthorizedHandler(async () => {})
})

describe('统一请求封装', () => {
  it('使用 /api、超时配置并携带 Bearer Token', async () => {
    const adapter = vi.fn(responseAdapter({ code: 200, data: { id: 1 } }))
    await expect(request.get('/goods', { adapter })).resolves.toEqual({ id: 1 })
    const config = adapter.mock.calls[0][0]
    expect(config.baseURL).toBe('/api')
    expect(config.timeout).toBe(15000)
    expect(config.headers.get('Authorization')).toBe('Bearer test-token')
  })
  it('公开认证接口可以跳过 Token，并兼容普通 JSON', async () => {
    const adapter = vi.fn(responseAdapter({ token: 'new-token' }))
    await expect(request.post('/auth/login', {}, { adapter, skipAuth: true })).resolves.toEqual({ token: 'new-token' })
    expect(adapter.mock.calls[0][0].headers.has('Authorization')).toBe(false)
  })
  it('业务失败会提示并 reject，不会当作成功', async () => {
    await expect(request.get('/goods', { adapter: responseAdapter({ code: 400, msg: '参数错误', data: null }) })).rejects.toThrow('参数错误')
    expect(ElMessage.error).toHaveBeenCalledOnce()
  })
  it('并发 HTTP 401 只调用一次失效处理', async () => {
    let finish
    const handler = vi.fn(() => new Promise((resolve) => { finish = resolve }))
    setUnauthorizedHandler(handler)
    const pending = Promise.allSettled([
      request.get('/orders', { adapter: failureAdapter(401) }),
      request.get('/publish', { adapter: failureAdapter(401) }),
    ])
    await vi.waitFor(() => expect(handler).toHaveBeenCalledOnce())
    finish()
    expect((await pending).every((result) => result.status === 'rejected')).toBe(true)
    expect(ElMessage.error).toHaveBeenCalledOnce()
  })
  it('业务码 401 也触发失效处理', async () => {
    const handler = vi.fn(async () => {})
    setUnauthorizedHandler(handler)
    await expect(request.get('/orders', { adapter: responseAdapter({ code: 401 }) })).rejects.toThrow()
    expect(handler).toHaveBeenCalledOnce()
  })
  it('登录密码错误的 401 不触发跳转', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    await expect(request.post('/auth/login', {}, {
      adapter: failureAdapter(401, { code: 401, msg: '密码错误', data: null }), authFailureRedirect: false,
    })).rejects.toThrow('密码错误')
    expect(handler).not.toHaveBeenCalled()
    expect(ElMessage.error).toHaveBeenCalledWith('密码错误')
  })
  it('注册冲突读取 msg，并交给表单显示错误', async () => {
    const body = { code: 409, msg: '用户名已存在，请前往登录或更换用户名', data: null }
    const error = await request.post('/auth/register', {}, {
      adapter: failureAdapter(409, body), inlineError: true, authFailureRedirect: false,
    }).catch((failure) => failure)
    expect(error).toBeInstanceOf(Error)
    expect(error.message).toBe(body.msg)
    expect(error.status).toBe(409)
    expect(ElMessage.error).not.toHaveBeenCalled()
  })
  it('超时提示与取消请求分别处理', async () => {
    const adapter = async (config) => { throw new axios.AxiosError('timeout', 'ECONNABORTED', config) }
    await expect(request.get('/goods', { adapter })).rejects.toThrow('请求超时')
    ElMessage.error.mockClear()
    const controller = new AbortController()
    controller.abort()
    await expect(request.get('/goods', { signal: controller.signal })).rejects.toSatisfy(axios.isCancel)
    expect(ElMessage.error).not.toHaveBeenCalled()
  })
})

it('登录回跳只接受安全的站内路径', () => {
  expect(safeRedirect('/publish?id=123')).toBe('/publish?id=123')
  for (const path of ['https://example.com', '//example.com', '/\\example.com', '/login', '/register?x=1', ['/orders']]) {
    expect(safeRedirect(path)).toBe('/')
  }
})
