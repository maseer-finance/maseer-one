## MaseerOne

Prototype

### Readable Functions (Pure/View)
- **DOMAIN_SEPARATOR()**: `bytes32`
- **allowance(address , address )**: `uint256`
- **balanceOf(address )**: `uint256`
- **cop()**: `address`
- **decimals()**: `uint8`
- **gem()**: `address`
- **name()**: `string`
- **nonces(address )**: `uint256`
- **pendingClaim(address )**: `uint256`
- **pendingTime(address )**: `uint256`
- **pip()**: `address`
- **symbol()**: `string`
- **totalPending()**: `uint256`
- **totalSupply()**: `uint256`

### Writable Functions (Non-Pure/Non-View)
- **approve(address guy, uint256 wad)**: `bool`
- **approve(address guy)**: `bool`
- **claim()**: ``
- **mint(uint256 amt_)**: ``
- **permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)**: ``
- **redeem(uint256 amt_)**: ``
- **settle()**: ``
- **transfer(address dst, uint256 wad)**: `bool`
- **transferFrom(address src, address dst, uint256 wad)**: `bool`
