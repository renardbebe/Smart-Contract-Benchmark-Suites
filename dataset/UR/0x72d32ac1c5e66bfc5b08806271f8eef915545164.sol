 

pragma solidity ^0.4.19;


 
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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Dec {
    function decimals() public view returns (uint8);
}

contract KeeToken is ERC20, Ownable {
     
    string public symbol = "KEE";
    uint8 public decimals = 0;
    uint public totalSupply = 1000;  
    string public name = "CryptoKEE";

    struct AddRec {
        address add;
        uint8   decimals;
    }

     
    AddRec[] eligible;
    AddRec temp;
         
         
         
         
         
         
         
        

    mapping (address => bool) public tokenIncluded;
    mapping (address => uint256) public bitRegisters;
    mapping (address => mapping(address => uint256)) public allowed;

    uint256[] public icoArray;

     

    function KeeToken() public {
        addToken(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280,10);
        addToken(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942, 18);
        addToken(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07, 18);
        addToken(0x7C5A0CE9267ED19B22F8cae653F198e3E8daf098, 18);
        addToken(0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d, 8);
        addToken(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C, 18);
        addToken(0x667088b212ce3d06a1b553a7221E1fD19000d9aF, 18);
        addToken(0xCb94be6f13A1182E4A4B6140cb7bf2025d28e41B, 6);
        addToken(0xFf3519eeeEA3e76F1F699CCcE5E23ee0bdDa41aC, 0);
        addToken(0xE94327D07Fc17907b4DB788E5aDf2ed424adDff6, 18);
        addToken(0x12FEF5e57bF45873Cd9B62E9DBd7BFb99e32D73e, 18);
        addToken(0xE7775A6e9Bcf904eb39DA2b68c5efb4F9360e08C, 6);
        addToken(0x4156D3342D5c385a87D264F90653733592000581, 8);
        addToken(0x58ca3065C0F24C7c96Aee8d6056b5B5deCf9c2f8, 18);
        addToken(0x22F0AF8D78851b72EE799e05F54A77001586B18A, 0);

        uint mask = 0;
        for (uint i = 0; i < eligible.length; i++) {
            tokenIncluded[eligible[i].add] = true;
        }
        icoArray.push(0);        
        icoArray.push(~mask >> 256 - eligible.length);
    }

     

    function updateICOmask(uint256 maskPos, uint256 newMask) external onlyOwner {
        require(maskPos != 0);  
        require(maskPos < icoArray.length);
        icoArray[maskPos] = newMask;
    }

    function setICObyAddress(address ico, uint256 maskPos) external onlyOwner {
        require(maskPos != 0);
        require(maskPos < icoArray.length);
        bitRegisters[ico] = maskPos;
    }

    function clearICObyAddress(address ico) external onlyOwner {
        bitRegisters[ico] = 0;
    }

    function icoBalanceOf(address from, address ico) external view returns (uint) {
        uint icoMaskPtr = bitRegisters[ico];
        return icoNumberBalanceOf(from,icoMaskPtr);
    }

     

    function pushICO(uint256 mask) public onlyOwner {
        icoArray.push(mask);
    }


    function addToken(address newToken, uint8 decimalPlaces) public onlyOwner {
        if (tokenIncluded[newToken]) {
            return;
        }
        temp.add = newToken;
        temp.decimals = decimalPlaces;
        
        eligible.push(temp);
        tokenIncluded[newToken] = true;
    }
    
    function updateToken(uint tokenPos, address newToken, uint8 decimalPlaces)  public onlyOwner {
        require(tokenPos < eligible.length);
        eligible[tokenPos].decimals = decimalPlaces;
        eligible[tokenPos].add = newToken;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender,spender,value);
    }

    function transfer(address to, uint) public returns (bool) {
        return transferX(msg.sender,to);
    }

    function transferFrom(address from, address to, uint) public returns (bool) {
        if (allowed[from][msg.sender] == 0) {
            return false;
        }
        return transferX(from,to);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function balanceOf(address from) public view returns (uint) {
        uint zero = 0;
        return internalBalanceOf(from,~zero);
    }

    function icoNumberBalanceOf(address from, uint icoMaskPtr) public view returns (uint) {
        if (icoMaskPtr == 0) 
            return 0;
        if (icoMaskPtr >= icoArray.length) 
            return 0;
        uint icoRegister = icoArray[icoMaskPtr];
        return internalBalanceOf(from,icoRegister);
    }

     

    function transferX(address from, address to) internal returns (bool) {
        uint myRegister = bitRegisters[from];
        uint yourRegister = bitRegisters[to];
        uint sent = 0;
        uint added = 0;
        for (uint i = 0; i < eligible.length; i++) {
            if (coinBal(eligible[i],from) > 100) {
                myRegister |= (uint(1) << i);
                added++;
            }
        }
        if (added > 0) {
            bitRegisters[from] = myRegister;
        }      
        if ((myRegister & ~yourRegister) > 0) {
            sent = 1;
            bitRegisters[to] = yourRegister | myRegister;
        }
        Transfer(from,to,sent);
        return true;        
    }

    function internalBalanceOf(address from, uint icoRegister) internal view returns (uint) {
        uint myRegister = bitRegisters[from] & icoRegister;
        uint bal = 0;
        for (uint i = 0; i < eligible.length; i++) {
            uint bit = (uint(1) << i);
            if ( bit & icoRegister == 0 )
                continue;
            if ( myRegister & bit > 0 ) {
                bal++;
                continue;
            }
            uint coins = coinBal(eligible[i], from);
            if (coins > 100) 
                bal++;
        }
        return bal;
    }

     

    function coinBal(AddRec ico, address from) internal view returns (uint) {
        uint bal = ERC20(ico.add).balanceOf(from);
        return bal / (10 ** uint(ico.decimals));
    }

}