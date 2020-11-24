 

pragma solidity ^0.4.18;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


 
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract BurnableErc20 is ERC20 {
    function burn(uint value) external;
}

contract KyberNetwork {
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
}


 
 
 
 
contract Burner is Destructible {
     
    KyberNetwork public kyberContract;

     
    BurnableErc20 public destErc20;

     
     
    function Burner(address _destErc20, address _kyberContract) public {
         
        require(_destErc20 != address(0));
        require(_kyberContract != address(0));

        destErc20 = BurnableErc20(_destErc20);
        kyberContract = KyberNetwork(_kyberContract);
    }
    
     
    function() public payable { }

     
     
     
     
     
     
    function burn(uint _maxSrcAmount, uint _maxDestAmount, uint _minConversionRate)
        external
        returns(uint)
    {
         
         
        uint ethToConvert = address(this).balance;
        if (_maxSrcAmount != 0 && _maxSrcAmount < ethToConvert) {
            ethToConvert = _maxSrcAmount;
        }

         
        uint maxDestAmount = _maxDestAmount != 0 ? _maxDestAmount : 2**256 - 1;

         
         
        uint minConversionRate = _minConversionRate != 0 ? _minConversionRate : 1;

         
         
        uint erc20ToBurn = kyberContract.trade.value(ethToConvert)(
             
            ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            
             
            ethToConvert,

             
            ERC20(destErc20),
            
             
            this,
            
             
            maxDestAmount,
            
             
            minConversionRate,
            
             
            0
        );

         
        destErc20.burn(erc20ToBurn);

        return erc20ToBurn;
    }

       
    function setKyberNetworkContract(address _kyberNetworkAddress) 
        external
        onlyOwner
    {
        kyberContract = KyberNetwork(_kyberNetworkAddress);
    }
}