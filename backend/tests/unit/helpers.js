function mockRequest({ params = {}, body = {}, query = {}, headers = {}, user = { id: 1 } } = {}) {
  return { params, body, query, headers, user };
}

function mockResponse() {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
}

module.exports = { mockRequest, mockResponse };
