 

 
 
 
 

 
 
 
 

 
 

pragma solidity ^0.4.13;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

 
 

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable public returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}

contract Controlled {
     
     
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

     
     
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract TokenTransferGuard {
    function onTokenTransfer(address _from, address _to, uint _amount) public returns (bool);
}

contract SwapController is DSAuth, TokenController {
    Controlled public controlled;

    TokenTransferGuard[] guards;

    function SwapController(address _token, address[] _guards)
    {
        controlled = Controlled(_token);

        for (uint i=0; i<_guards.length; i++) {
            addGuard(_guards[i]);
        }
    }

    function changeController(address _newController) public auth {
        controlled.changeController(_newController);
    }

    function proxyPayment(address _owner) payable public returns (bool)
    {
        return false;
    }

    function onTransfer(address _from, address _to, uint _amount) public returns (bool)
    {
        for (uint i=0; i<guards.length; i++)
        {
            if (!guards[i].onTokenTransfer(_from, _to, _amount))
            {
                return false;
            }
        }

        return true;
    }

    function onApprove(address _owner, address _spender, uint _amount) public returns (bool)
    {
        return true;
    }

    function addGuard(address _guard) public auth
    {
        guards.push(TokenTransferGuard(_guard));
    }
}