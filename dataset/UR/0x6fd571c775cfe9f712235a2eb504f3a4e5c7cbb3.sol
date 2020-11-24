 
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
 
    address private _locker;
    address private _issuer;
    uint256 private _releaseTime;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 supply, address locker, address issuer) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _locker = locker;
        _issuer = issuer;
        _releaseTime = block.timestamp + 72 weeks;
        _mint(address(this), supply * uint256(10)**uint256(decimals) * 1 / 4);
        _mint(_issuer, supply * uint256(10)**uint256(decimals) * 3 / 4);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

    function issuer() public view returns (address) {
        return _issuer;
    }

    function locker() public view returns (address) {
        return _locker;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function release() public {
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _transfer(address(this), _locker, amount);
    }
}
