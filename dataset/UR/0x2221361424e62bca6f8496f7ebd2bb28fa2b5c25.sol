 

pragma solidity ^0.5.2;
contract Ownable {
    address  private  _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ExChangeProxy is Ownable {
    mapping(uint256 => address) public exchanges;
    mapping(address => uint256) public proxys;
    
    event SetExchange(uint256 indexed exchangeCode,address indexed exchangeAddress);
    
    constructor() public {}
    
    function setExchange(uint256 _e,address _exchange) 
        public
        onlyOwner
    {
        require(_e>0 && _exchange != address(0) && _exchange != address(this),"Invalid exchange code");
        exchanges[_e] = _exchange;
        emit SetExchange(_e,_exchange);
    }
    
    function bathSetCollection(address[] memory _proxy,uint256 _e)
        public
        onlyOwner
    {
        require(exchanges[_e] != address(0),"Invalid exchange code");
        for(uint256 i;i<_proxy.length;i++){
            proxys[_proxy[i]] = _e;
        }
    }
    
    function getexchange(address proxy)
        public
        view
        returns(address exchange)
    {
        uint256 _code = proxys[proxy];
        if(_code >0){
            exchange = exchanges[_code];
        }
    }
    
    function removeproxy(address proxy)
        public
        onlyOwner
        returns(bool)
    {
        require(proxys[proxy] >0 ,"not a proxy  valid address");
        proxys[proxy] = 0;
    }
}