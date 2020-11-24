 
contract RaeToken is ERC20Detailed, ERC20Capped, ERC20Burnable, ERC20Pausable {
    uint256 private _mintAmount = 216000e18;
    uint256 private _mintPeriods = 0;
    uint256 private _totalInPeriod = 0;
    uint256 constant private _halveEvery = 1700;  
    mapping (address => uint256) private _balances;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 cap)
        ERC20Burnable()
        ERC20Mintable()
        ERC20Capped(cap)
        ERC20Detailed(name, symbol, decimals)
        ERC20Pausable()
        ERC20()
    public 
    {
        _mint(msg.sender, 84000e18);
    }

     
    function mintBulk(address[] calldata addresses, uint256[] calldata values) external whenNotPaused onlyMinter returns (bool) {
        
        require(addresses.length > 0);
        require(addresses.length == values.length);

        for(uint256 i = 0; i < addresses.length; ++i) {
            _totalInPeriod = _totalInPeriod.add(values[i]);
            _mint(addresses[i], values[i]);
        }
        require(_totalInPeriod <= _mintAmount);
        if( _totalInPeriod == _mintAmount) _updateMintParams();

        return true;
    }


    function period() external view returns (uint256){
        return _mintPeriods;
    }

    function mintAmount() external view returns (uint256){
        return _mintAmount;
    }

    function _updateMintParams() internal returns (bool) {
         
        if(_mintPeriods == 0) _mintAmount = 10000e18;

         
        _mintPeriods = _mintPeriods.add(1);

         
        if(_mintPeriods % _halveEvery == 0) _mintAmount = _mintAmount.div(2);

         
        _totalInPeriod = 0;

        return true;
    }

    function remainingInPeriod() external view returns (uint256) {
        return _mintAmount - _totalInPeriod;
    }

    function totalInPeriod() external view returns (uint256) {
        return _totalInPeriod;
    }

     
    function mint(address to, uint256 value) public whenNotPaused onlyMinter returns (bool) {
         
        revert();
    }

     
    function burn(uint256 value) public whenNotPaused {
        super.burn(value);
    }

    function burnFrom(address from, uint256 value) public whenNotPaused {
        super.burnFrom(from, value);
    }

}