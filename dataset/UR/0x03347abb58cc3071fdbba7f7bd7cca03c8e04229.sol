 

pragma solidity ^0.4.24;

contract CompanyShare {
    using SafeMath for *;

    mapping (address => uint256) public pIDxAddr_;           
    mapping (uint256 => CompanySharedatasets.Player) public team_;           

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    constructor()
        public
    {
        address first = 0x7ce07aa2fc356fa52f622c1f4df1e8eaad7febf0;
        address second = 0x6b5d2ba1691e30376a394c13e38f48e25634724f;
        address third = 0x459b5286e28d0dd452af4f38ffed4d302fc833c8;
        address fourth = 0xd775c5063bef4eda77a21646a6880494d9a1156b;

         
        team_[1] = CompanySharedatasets.Player(first,0, 500);
        pIDxAddr_[first] = 1;
        team_[2] = CompanySharedatasets.Player(second,0, 250);
        pIDxAddr_[second] = 2;
        team_[3] = CompanySharedatasets.Player(third,0, 125);
        pIDxAddr_[third] = 3;
        team_[4] = CompanySharedatasets.Player(fourth,0, 125);
        pIDxAddr_[fourth] = 4;
	}

     
    function()
        public
        payable
    {
        uint256 _eth = msg.value;
         
        giveGen(_eth);
    }

    function deposit()
        public
        payable
        returns(bool)
    {
        uint256 _eth = msg.value;
         
        giveGen(_eth);
        return true;
    }

	function giveGen(uint256 _eth)
		private
		returns(uint256)
    {
        uint256 _genFirst = _eth.mul(team_[1].percent) /1000;
        uint256 _genSecond = _eth.mul(team_[2].percent) /1000;
        uint256 _genThird = _eth.mul(team_[3].percent) /1000;
        uint256 _genFourth = _eth.sub(_genFirst).sub(_genSecond).sub(_genThird);
         
        team_[1].gen = _genFirst.add(team_[1].gen);
        team_[2].gen = _genSecond.add(team_[2].gen);
        team_[3].gen = _genThird.add(team_[3].gen);
        team_[4].gen = _genFourth.add(team_[4].gen);
    }

         
    function withdraw()
        isHuman()
        public
    {
         
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0, "sorry not team");
         
        uint256 _eth;
         
        _eth = withdrawEarnings(_pID);
        team_[_pID].addr.transfer(_eth);
    }

         
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {

         
        uint256 _earnings = team_[_pID].gen;
        if (_earnings > 0)
        {
            team_[_pID].gen = 0;
        }

        return(_earnings);
    }

    function getGen()
		public
		view
		returns(uint256)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
        require(_pID != 0, "sorry not in team");
        uint256 _earnings = team_[_pID].gen;
        return _earnings;
    }
    
    
     function destroy() public{  
         require(msg.sender == 0x7ce07aa2fc356fa52f622c1f4df1e8eaad7febf0, "sorry not the admin");
         suicide(0x7ce07aa2fc356fa52f622c1f4df1e8eaad7febf0);  
     }
}


 
 
 
 
library CompanySharedatasets {
     
    struct Player {
        address addr;    
        uint256 gen;     
        uint256 percent;     
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

     
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}