 

pragma solidity >=0.5; 


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = tx.origin;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
interface IGasStorage
{
    function mint(uint256 value) external;
    function burn(uint256 value) external;
    function balanceOf() external view returns (uint256 balance);
} 

 
interface GasToken
{
     function mint(uint256 value) external;
     function free(uint256 value) external;
     function freeUpTo(uint256 value) external returns (uint256 freed);
     function balanceOf(address owner) external view returns (uint256 balance);
     function transfer(address to, uint256 value) external returns (bool success);
} 

  
contract GasStorage is IGasStorage,Ownable
{
    address _dex; 
    address _gasToken;

    uint256 _baseBurn;
    uint256 _eachBurnBase;

    event GasStatus(uint256 gasLeft,uint256 gasUsed);
    event GasMined(address miner,uint256 mineAmount);

    modifier onlyDex {
        if (msg.sender != _dex ) return;
        _;
    }  

    constructor(address dex,address gasToken) public {
        _dex = dex;   
        _gasToken = gasToken;
        _baseBurn = 15000;
        _eachBurnBase = 20000;
    }  

    function setDex(address dex) public onlyOwner{
        _dex = dex;
    }

    function setGasToken(address gasToken) public onlyOwner{
        _gasToken = gasToken;
    } 
 
    function setBaseBurn(uint256 baseBurn) public onlyOwner{
        _baseBurn = baseBurn;
    }
 
    
    function setEachBurnBase(uint256 eachBurnBase) public onlyOwner{
        _eachBurnBase = eachBurnBase;
    }

    
    function mint(uint256 value)  public
    {
        if( _gasToken != address(0))
        { 
            GasToken(_gasToken).mint(value); 
            emit GasMined(msg.sender,value);
        }
    } 
 
    
    function burn(uint256 value) public onlyDex
    {
        if( _gasToken == address(0))
        {
            return;
        } 

        if(GasToken(_gasToken).balanceOf(address(this)) == 0){
            return;
        } 

        uint256 gasLeftSaved = gasleft();
        emit GasStatus(gasLeftSaved,value);

        uint256 burnNumber = (value + _baseBurn) / _eachBurnBase;
 
        GasToken(_gasToken).freeUpTo(burnNumber); 

        emit GasStatus(gasleft(), gasLeftSaved - gasleft());
    }

    
    function balanceOf() public view returns (uint256 balance)
    {
        if( _gasToken != address(0))
        {
            return GasToken(_gasToken).balanceOf(address(this));
        } 

        return 0;
    }

    
    function transfer(address to,uint256 amount) public onlyOwner{

        if( _gasToken == address(0))
        {
            return;
        } 

        GasToken(_gasToken).transfer(to,amount);
    }
}