/**
 * Cloudflare Pages 镜像（Advanced Mode）：把请求转发到 pi-agent-cloud Worker。
 * workers.dev 在大陆被 DNS 污染，pages.dev 实测可达；Pages 与 Worker 在
 * Cloudflare 边缘内部互访，不经过用户侧 DNS。
 */
const UPSTREAM = 'https://pi-agent-cloud.dongchangyang.workers.dev';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const upstream = new Request(UPSTREAM + url.pathname + url.search, request);
    const res = await fetch(upstream);
    const location = res.headers.get('location');
    if (location && location.startsWith(UPSTREAM)) {
      const headers = new Headers(res.headers);
      headers.set('location', url.origin + location.slice(UPSTREAM.length));
      return new Response(res.body, { status: res.status, headers });
    }
    return res;
  },
};
