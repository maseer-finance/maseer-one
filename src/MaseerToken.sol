// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

abstract contract MaseerToken {

    // ERC-20
    uint256                                           public totalSupply;
    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    string                                            public name;
    string                                            public symbol;
    uint8                                    constant public decimals = 18; // standard token precision.

    // EIP-2612
    bytes32 immutable           public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;
    uint256 immutable         internal CHAIN_ID; // token is linked to deployment chain id. Forked chains are not supported.

    constructor(string memory name_, string memory symbol_) {
        name   = name_;
        symbol = symbol_;

        CHAIN_ID = block.chainid;
        DOMAIN_SEPARATOR = _domainSeparator();
    }

    event Approval(address indexed src, address indexed usr, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    function approve(address usr) external virtual returns (bool) {
        return approve(usr, type(uint256).max);
    }

    function approve(address usr, uint wad) public virtual returns (bool) {
        allowance[msg.sender][usr] = wad;

        emit Approval(msg.sender, usr, wad);

        return true;
    }

    function transfer(address dst, uint wad) external virtual returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public virtual
        returns (bool)
    {
        uint256 _allowance = allowance[src][msg.sender];
        if (_allowance != type(uint256).max) {
            allowance[src][msg.sender] = _allowance - wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.chainid == CHAIN_ID,   "INVALID_CHAIN");
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the owner's nonce is uint256 which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function _mint(address usr, uint wad) internal {
        totalSupply += wad;
        // Cannot overflow
        unchecked {
            balanceOf[usr] += wad;
        }
        emit Transfer(address(0), usr, wad);
    }

    function _burn(address usr, uint wad) internal {
        balanceOf[usr] -= wad;
        // Cannot overflow
        unchecked {
            totalSupply -= wad;
        }
        emit Transfer(usr, address(0), wad);
    }

    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            CHAIN_ID,
            address(this)
        ));
    }
}
