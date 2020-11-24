 

contract DFNTokens {
   
  string public name;

   
  mapping(address => uint) public balance;

   
  mapping(address => bool) public authorizedToTransfer;

   
  address public owner;

   
  bytes32[] public notarizationList;

   
  bool public frozen = false;

   
  uint public freezeHeight = 0;

   
   
  address[] public addrList;
   
  mapping(address => bool) public seen;
   
  uint public nAddresses = 0;

   
  function DFNTokens() public {
      name = "test";

       
      owner = msg.sender;

       
      balance[0x0] = 469213710;

       
      TransferDFN(0x0, 0x1, 44575302);
      TransferDFN(0x0, 0x2, 115986694);
      TransferDFN(0x0, 0x3, 308651714);
  }

   
  modifier onlyowner {
      require(msg.sender == owner);
      _;
  }

  modifier onlyauthorized {
      require(msg.sender == owner || authorizedToTransfer[msg.sender] == true);
      _;
  }

  modifier alive {
      require(!frozen);
      _;
  }

   
  function TransferDFN(address from, address to, uint amt) onlyauthorized alive public {
    require(0 < amt && amt <= balance[from]);

     
    balance[to] += amt;
    balance[from] -= amt;

     
    if (!seen[to]) {
        addrList.push(to);
        seen[to] = true;
        nAddresses += 1;
    }
  }

 
function AuthorizeToTransfer(address newAddr) onlyowner alive public {
    authorizedToTransfer[newAddr] = true;
}

 
function UnauthorizeToTransfer(address addr) onlyowner alive public {
    authorizedToTransfer[addr] = false;
}

 
function Notarize(bytes32 hash) onlyowner alive public {
    notarizationList.push(hash);
}

 
function Freeze() onlyowner alive public {
     
    if (freezeHeight > 0 && block.number < freezeHeight + 20) { frozen = true; }

     
    freezeHeight = block.number;
}

 
function emptyTo(address addr) onlyowner public {
    addr.transfer(address(this).balance);
}

}