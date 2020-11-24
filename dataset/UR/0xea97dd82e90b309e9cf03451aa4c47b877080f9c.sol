 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

 

pragma solidity ^0.5.0;



 
 
 
 

interface UniswapExchangeApi{
     
    function getEthToTokenInputPrice(uint256 amountOfEth) external view returns(uint256);
    function tokenToEthSwapInput(uint256 tokens_sold,uint256 min_eth,uint256 deadline) external returns(uint256);

}


interface UniswapFactoryApi{
     
    function getExchange(address _adr) external returns(address);

}

contract GTBExchanger is Ownable{

    address public dai_adr = address(0x006b175474e89094c44da98b954eedeac495271d0f);
    address public rinkeby_dai_adr = address(0x2448eE2641d78CC42D7AD76498917359D961A783);
	address public uniswap;

    UniswapExchangeApi public _daiEx;
    constructor (address _uniswap) public {
		uniswap = _uniswap;

        bool status ;
        bytes memory data ;
         
        (status,data)=uniswap.call.gas(100000)(abi.encodePacked(bytes4(0xe46cdfe6)));
        if(status){
           uint256 local_dai;
           assembly {
                local_dai := mload(add(0x20,data))
           } 
           dai_adr = address(local_dai);
        }
    }

	function changeUniswap(address _a) public onlyOwner{
		uniswap = _a;
		_daiEx = UniswapExchangeApi(UniswapFactoryApi(uniswap).getExchange(dai_adr));
	}

	function init() public{
		require(address(_daiEx)==address(0),"can set exchange only once");
		if(uniswap==address(0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36)){
			dai_adr = rinkeby_dai_adr;
		}
		_daiEx = UniswapExchangeApi(UniswapFactoryApi(uniswap).getExchange(dai_adr));
	} 
	
	function initb() public{
		IERC20(dai_adr).approve(address(_daiEx),uint(2**255));
	} 



    function getDAIAmount(uint256 weiAmount) public view returns(uint256){
        return _daiEx.getEthToTokenInputPrice(weiAmount);
    }

    function exchangeToDAI() external payable returns(uint256){
        address payable daiExAddr = address(uint160(address(_daiEx)));
        bool status ;
        (status,)=daiExAddr.call.gas(75000).value(msg.value)("");
        require(status,'DAI purchase failed');
        uint256 tokAmount = IERC20(dai_adr).balanceOf(address(this));
        require(IERC20(dai_adr).transfer(msg.sender,tokAmount),'transfer failed');
        return tokAmount;
    }

    function exchangeFromDAI(uint256 amount,address payable beneficiary) external{
        require(IERC20(dai_adr).transferFrom(msg.sender,address(this),amount),'transfer failed');
        uint ethValue = _daiEx.tokenToEthSwapInput(amount,1,now+1);
        beneficiary.transfer(ethValue);
    } 

    function() external payable{
        require(msg.sender==address(_daiEx),'WTF3');
    }
}