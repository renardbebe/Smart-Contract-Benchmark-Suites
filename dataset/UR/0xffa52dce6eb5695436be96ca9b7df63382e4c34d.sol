 

pragma solidity ^0.5.11;

library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface USDContract{
     function sendFunds() external payable;
     function ethPricerAddress() external view returns (address);
     function multiplier() external view returns (uint256);
     function assetContracts(address input) external view returns (bool);
     function USDtrade(address sender,uint amount) external;
     function primary() external view returns (address);
}

contract USDable {
    
    address payable private _USDcontractaddress = 0x7c0AFD49D40Ec308d49E2926E5c99B037d54EE7e;
    
    function USDcontractaddress() internal view returns (address){
        return _USDcontractaddress;
    }
    
    function setUSDcontractaddress(address payable input) public {
        require(msg.sender == USDContract(USDcontractaddress()).primary(), "Secondary: caller is not the primary account");
        require(input != address(this));
        require(!assetContracts(input));
        require(input != msg.sender);
        require(input != address(0));
        require(msg.sender == USDContract(input).primary());
        
        _USDcontractaddress = input;
    }
    
    modifier onlyUSDContract() {
        require(msg.sender == _USDcontractaddress, "You cannot call this function!");
        _;
    }
    
    function sendFunds(uint amount) internal {
        USDContract(_USDcontractaddress).sendFunds.value(amount)();
    }
    
    function ethPricerAddress() internal view returns (address) {
        return USDContract(_USDcontractaddress).ethPricerAddress();
    }
    
    function multiplier() internal view returns (uint256) {
        return USDContract(_USDcontractaddress).multiplier();}
    
    function assetContracts(address input) internal view returns (bool) {
        return USDContract(_USDcontractaddress).assetContracts(input);
    }
    
    function USDtrade(address sender,uint amount) internal {
        return USDContract(_USDcontractaddress).USDtrade(sender,amount);
    }
    
}

contract Secondary is USDable{
    
    modifier onlyPrimary() {
        require(msg.sender == USDContract(USDcontractaddress()).primary(), "Secondary: caller is not the primary account");
        _;
    }

    function primary() internal view returns (address) {
        return USDContract(USDcontractaddress()).primary();
    }
}

interface EthPricer{
    function ethUpper() external view returns (uint256);
    function ethLower() external view returns (uint256);
}

contract EthPriceable is Secondary{
    
    function ethUpper() internal view returns (uint256) {
        return EthPricer(ethPricerAddress()).ethUpper();
    }
    
    function ethLower() internal view returns (uint256) {
        return EthPricer(ethPricerAddress()).ethLower();
    }
}

interface AssetPricer{
    function updateAssetPrice() external payable returns (bytes32);
    function Fee() external returns (uint256);
    function assetUpper(bool isShort) external view returns (uint256);
    function assetLower(bool isShort) external view returns (uint256);
    function updateGasPrice() external;
}

contract AssetPriceable is Secondary{
    using SafeMath for uint256;
    
    address payable private _assetPricerAddress;
    
    bool constant private _isShort = true;
    
    function setAssetPricerAddress(address payable input) public onlyPrimary {
        require(input != USDcontractaddress());
        require(input != address(this));
        require(!assetContracts(input));
        require(input != msg.sender);
        require(input != address(0));
    
        _assetPricerAddress = input;
    }
    
    modifier onlyAssetPricer() {
        require(msg.sender == _assetPricerAddress, "You cannot call this function!");
        _;
    }
    
    function Fee() internal returns (uint256) {
        AssetPricer(_assetPricerAddress).updateGasPrice();
        uint fee = AssetPricer(_assetPricerAddress).Fee();
        return (fee.mul(multiplier().add(100))).div(100);
    }
    
    function assetUpper() internal view returns (uint256) {
        return AssetPricer(_assetPricerAddress).assetUpper(_isShort);
    }
    
    function assetLower() internal view returns (uint256) {
        return AssetPricer(_assetPricerAddress).assetLower(_isShort);
    }
    
    function updateAssetPrice() internal returns (bytes32) {
        AssetPricer(_assetPricerAddress).updateGasPrice();
        uint fee = AssetPricer(_assetPricerAddress).Fee();
        return AssetPricer(_assetPricerAddress).updateAssetPrice.value(fee)();
    }
    
    function assetPricerAddress() public view onlyUSDContract returns (address) {
        return _assetPricerAddress;
    }
    
    function isShort() public view onlyUSDContract returns (bool) {
        return _isShort;
    }

}

contract ERC20 is IERC20, EthPriceable, AssetPriceable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(recipient != USDcontractaddress(), "You can only send tokens to their own contract!");
        
        if(recipient == address(this)){
            require(amount > (Fee().mul(ethUpper())).div(assetLower()), "Amount sent is too small");
            _burn(sender,amount);
            USDtrade(sender,amount);
            
        }else{
             require(!assetContracts(recipient), "You can only send tokens to their own contract!");
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(value);
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

interface token {
    function balanceOf(address input) external returns (uint256);
    function transfer(address input, uint amount) external;
}

contract AssetToken is ERC20, ERC20Detailed {
    
    mapping(bytes32=>customer) private Customers;
    
    struct customer {
        address myAddress;
        uint256 valuesent;
    }
    
    constructor () public ERC20Detailed("Onyx S&P 500 Short", "OSPVS", 18) {
        _mint(primary(),10**18);
    }
    
    function () external payable {
        uint total = address(this).balance;
        bytes32 customerId = updateAssetPrice();
        uint amount = msg.value.sub(total.sub(address(this).balance));
        Customers[customerId] = customer(msg.sender, amount);
    }

    function assetPriceUpdated(bytes32 customerId, bool marketOpen) public onlyAssetPricer {
        uint valuesent = Customers[customerId].valuesent;
        address myAddress = Customers[customerId].myAddress;
         
        if(marketOpen){
            uint amount = (ethLower().mul(valuesent)).div(assetUpper());
            _mint(myAddress, amount);
            sendFunds(valuesent);
             
        }else{
            address payable sendto = address(uint160(myAddress));
            sendto.transfer(valuesent);
        }   
    }
  
    function AssetMint(address to, uint256 valuesent) public {
        require(msg.sender == USDcontractaddress() || msg.sender == primary(), "You cannot call this function!");
        _mint(to,valuesent);
    }
    
    function AssetBurn(address to, uint256 valuesent) public  onlyPrimary{
        _burn(to,valuesent);
        emit Transfer(to, address(this), valuesent);
    }
    
    function getStuckTokens(address _tokenAddress) public {
        token(_tokenAddress).transfer(primary(), token(_tokenAddress).balanceOf(address(this)));
    }

    function getLostFunds() public onlyPrimary {
        sendFunds(address(this).balance);
    } 
}