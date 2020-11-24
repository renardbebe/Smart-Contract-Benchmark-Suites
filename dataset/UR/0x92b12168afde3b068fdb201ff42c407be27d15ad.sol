 

pragma solidity ^0.4.25;

contract Gravestone {
	 
	string public fullname;
	 
	string public birth_date;
	 
	string public death_date;
	
	 
	string public epitaph;
	
     
    Worship[] public worships;
	uint public worship_count;
	
	 
	constructor(string _fullname,string _birth_date,string _death_date,string _epitaph) public {
		fullname = _fullname;
		birth_date = _birth_date;
		death_date = _death_date;
		epitaph = _epitaph;
	}

     
    function do_worship(string _fullname,string _message) public returns (string) {
		uint id = worships.length++;
		worship_count = worships.length;
		worships[id] = Worship({fullname: _fullname, message: _message});
        return "Thank you";
    }
	
	struct Worship {
		 
		string fullname;
		 
		string message;
	}
}

contract JinYongGravestone is Gravestone {
	constructor() Gravestone("金庸","1924年3月10日","2018年10月30日","这里躺着一个人，在二十世纪、二十一世纪，他写过几十部武侠小说，这些小说为几亿人喜欢。") public {}
}