 

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

contract Secondary {
    address private _primary;
    address private _primaryCandidate;

    constructor () internal {
        _primary = msg.sender;
        _primaryCandidate = address(0);
    }

    modifier onlyPrimary() {
        require(msg.sender == _primary, "Secondary: caller is not the primary account");
        _;
    }

    function primary() public view returns (address) {
        return _primary;
    }
    
    function acceptBeingPrimary() public {
        require(msg.sender == _primaryCandidate, "Secondary: caller is not the primary candidate account");
        require(msg.sender != address(0));
        
        _primary = _primaryCandidate;
        _primaryCandidate = address(0);
    }

    function setPrimaryCandidate(address recipient) public onlyPrimary {
        require(recipient != _primary);
        _primaryCandidate = recipient;
    }
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

contract assetContractable is Secondary{
    mapping(address=>bool) private _assetContracts;
    
    modifier onlyAssetContracts() {
        require(_assetContracts[msg.sender], "You cannot call this function!");
        _;
    }
    
    function assetContracts(address input) public view returns (bool) {
        return _assetContracts[input];
    }
 
    function addAssetContracts(address input) public onlyPrimary{
         require(input != address(this));
         require(input != msg.sender);
         require(input != address(0));
         require(!assetContracts(input));
         
        _assetContracts[input] = true;
    }
    
    function removeAssetContracts(address input) public onlyPrimary{
         require(assetContracts(input));
        _assetContracts[input] = false;
    }
    
}

interface EthPricer{
    function ethUpper() external view returns (uint256);
    function ethLower() external view returns (uint256);
}

contract EthPriceable is assetContractable{
    
    address private _ethPricerAddress;
    
    function ethUpper() internal view returns (uint256) {
        return EthPricer(_ethPricerAddress).ethUpper();
    }
    
    function ethLower() internal view returns (uint256) {
        return EthPricer(_ethPricerAddress).ethLower();
    }
    
    function setEthPricerAddress(address input) public onlyPrimary {
        require(input != address(this));
        require(!assetContracts(input));
        require(input != msg.sender);
        require(input != address(0));
    
        _ethPricerAddress = input;
    }
    
    function ethPricerAddress() public view onlyAssetContracts returns (address) {
        return _ethPricerAddress;
    }

}

interface Assetcontract{
    function assetPricerAddress() external view returns (address payable);
    function AssetMint(address sender, uint256 valuesent) external;
    function isShort() external view returns (bool);
}

interface AssetPricer{
    function updateAssetPrice() external payable returns (bytes32);
    function Fee() external returns (uint256);
    function assetUpper(bool isShort) external view returns (uint256);
    function assetLower(bool isShort) external view returns (uint256);
    function updateGasPrice() external;
}

contract AssetPriceGettable is assetContractable{
    
    using SafeMath for uint256;

    uint256 internal _multiplier = 0;
    
    function multiplier() public view onlyAssetContracts returns (uint256) {
        return _multiplier;
    }
    
    function setMultiplier(uint256 input) public onlyPrimary {
        require(input <= 9999999900);
        _multiplier = input;
    }
    
    function aPA(address assetContractAddress) private view returns (address){
        return Assetcontract(assetContractAddress).assetPricerAddress();
    }

    function Fee(address aCA) internal returns (uint256) {
        AssetPricer(aPA(aCA)).updateGasPrice();
        uint fee = AssetPricer(aPA(aCA)).Fee();
        return (fee.mul(_multiplier.add(100))).div(100);
    }
    
    function assetUpper(address aCA) internal view returns (uint256) {
        bool isShort = Assetcontract(aCA).isShort();
        return AssetPricer(aPA(aCA)).assetUpper(isShort);
    }
    
    function assetLower(address aCA) internal view returns (uint256) {
        bool isShort = Assetcontract(aCA).isShort();
        return AssetPricer(aPA(aCA)).assetLower(isShort);
    }

    function updateAssetPrice(address aCA) internal returns (bytes32) {
        address payable sendto = address(uint160(aPA(aCA)));
        AssetPricer(sendto).updateGasPrice();
        return AssetPricer(sendto).updateAssetPrice.value(AssetPricer(sendto).Fee())();
    }
    
    function isAssetPricerAddress(address aCA, address input) internal view returns (bool) {
        return aPA(aCA) == input;
    }

}

contract ERC20 is IERC20, EthPriceable, AssetPriceGettable{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    
    uint constant internal DECIMAL = 10**18;
    
    mapping(bytes32=>customer) internal Customers;
    mapping(uint=>uint) private withdrawPerBlock;
    
    enum IdType { gettingAsset, gettingUSD}
    
    struct customer { 
        address sender;
        uint256 valuesent;
        address Assetcontract;
        IdType mytype;
    }
    
    uint256 private withdrawThreshold = 1;
    
    function updateWithdrawThreshold(uint256 _withdrawThreshold) public onlyPrimary {
        withdrawThreshold = _withdrawThreshold;
    }
    
     
    function withdrawMAX() public view returns (uint256){
        
        uint usdMAX = (address(this).balance.mul(ethUpper())).div(withdrawThreshold.mul(DECIMAL));
      
        if(withdrawPerBlock[block.number] < usdMAX){
            return usdMAX.sub(withdrawPerBlock[block.number]);
        }else{
            return 0;
        }
    }

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
        
        if(recipient == address(this)){
            require(amount <= withdrawMAX(), "Amount sent is too big");
            withdrawPerBlock[block.number] = withdrawPerBlock[block.number].add(amount);
            
            _burn(sender,amount);
            address payable sendto = address(uint160(sender));
            sendto.transfer(amount.mul(DECIMAL).div(ethUpper()));
            
        }else if(assetContracts(recipient)){

           uint USDFee = (Fee(recipient).mul(ethUpper())).div(DECIMAL);
           require(amount > USDFee, "Amount sent is too small");
           
           _burn(sender,amount);
           bytes32 CustomerId = updateAssetPrice(recipient);
           Customers[CustomerId] = customer(sender, amount.sub(USDFee), recipient, IdType.gettingAsset);
            
        }else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount,address sender ) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(sender, account, amount);
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

contract MainToken is ERC20, ERC20Detailed{

    constructor () public ERC20Detailed("Onyx USD", "OUSD", 18){
        _mint(primary(),10**18, address(this));
    }
    
    function () external payable {
        uint256 amount = (msg.value.mul(ethLower())).div(DECIMAL);
        _mint(msg.sender,amount,address(this));
    }
    
    function sendFunds() external payable {}
    
    function USDtrade(address sender, uint assetAmount) public onlyAssetContracts{
       bytes32 customerId = updateAssetPrice(msg.sender);
       Customers[customerId] = customer(sender, assetAmount, msg.sender,IdType.gettingUSD);
    }
    
    function assetPriceUpdated(bytes32 customerId, bool marketOpen) public {
       address sender    = Customers[customerId].sender;
       uint256 valuesent = Customers[customerId].valuesent;
       address AC        = Customers[customerId].Assetcontract;
       IdType mytype     = Customers[customerId].mytype;
       
       require(isAssetPricerAddress(AC, msg.sender));
       require(msg.sender != address(0));
       
       if(mytype == IdType.gettingUSD){

            if(marketOpen){
               uint amount = ((valuesent.mul(AssetPricer(msg.sender).assetLower(Assetcontract(AC).isShort())).mul(100)).sub(AssetPricer(msg.sender).Fee().mul(_multiplier+100).mul(ethUpper())))/(10**20);
               _mint(sender, amount, AC);
               
            }else{
               uint amount = valuesent.sub((AssetPricer(msg.sender).Fee().mul(_multiplier+100).mul(ethUpper())).div(AssetPricer(msg.sender).assetLower(Assetcontract(AC).isShort()).mul(100)));
               Assetcontract(AC).AssetMint(sender,amount); 
            }

        }else if(mytype == IdType.gettingAsset){

            if(marketOpen){
               uint amount = (valuesent.mul(DECIMAL)).div(assetUpper(AC));
               Assetcontract(AC).AssetMint(sender,amount);

            }else{
                _mint(sender, valuesent, AC);
            }
        }
    }
    
    function USDMint(address to, uint256 valuesent) public onlyPrimary{
        _mint(to,valuesent, address(this));
    }
 
    function USDBurn(address to, uint256 valuesent) public onlyPrimary {
        _burn(to,valuesent);
        emit Transfer(to, address(this), valuesent);
    }
    
    
    function getStuckTokens(address _tokenAddress) public {
        token(_tokenAddress).transfer(primary(), token(_tokenAddress).balanceOf(address(this)));
    }
   
    function withdrawEth(uint256 amount) public onlyPrimary{
        address payable sendto = address(uint160(primary()));
        sendto.transfer(amount);
    } 
}