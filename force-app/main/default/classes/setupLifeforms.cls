public class setupLifeforms
{
	public Map<Integer,Map<Integer,Lifeform__c>>       EcoSystem;    // first key is X Coord, second key is Y Coord
	public EcoSystemState__c                           theWorld;    
	// Direction Spiral, clockwise
	// If last direction was east, go south
	// south, go west
	// west, go north
	// north, go east
	Map<String, String>     DirMap;         // Key is last direction, value is trial direction
	Map<String, Move>       MoveMap;        // Key is desired direction, value is function pointer that handles the move
	List<Lifeform__c>       BioMass;

		////////////////////////////
		// Constructor            //
		////////////////////////////

	public setupLifeforms(  )
	{
		BioMass =
		[
			SELECT Alive__c, Index__c, X_Coordinate__c, Y_Coordinate__c,
				Neighbor_East__c, Neighbor_North__c, Neighbor_West__c , Neighbor_South__c,
				Neighbor_NE__c, Neighbor_NW__c , Neighbor_SE__c, Neighbor_SW__c
			FROM Lifeform__c
			ORDER BY Index__c ASC
		];
		EcoSystem = new Map<Integer,Map<Integer,Lifeform__c>>();

		MoveMap = new Map<String, Move>
		{
			'East' => new tryToGoSouth(),
			'South' => new tryToGoWest(),
			'West' => new tryToGoNorth(),
			'North' => new tryToGoEast()
		};

		setupWorld();
	}
 
		////////////////////////////
		// Utility Functions      //
		//   -setupWorld          //
		//   -resetEcosystem      //
		////////////////////////////

	public void setupWorld()
	{
		List<EcoSystemState__c> theStates = [SELECT Id, Direction__c, NewestLife__c FROM EcoSystemState__c];
		if ( theStates.isEmpty() )
		{
			theWorld = new EcoSystemState__c
			(
				NewestLife__c = BioMass.isEmpty() ? null : BioMass[0].Id, 
				Direction__c = 'South'
			);
			insert theWorld;
			return;
		} 

		theWorld = theStates.remove(0);
		if ( !theStates.isEmpty() ) 
		{
			// We don't need more than one world 
			System.Debug('There is more than one world');
			delete theStates;
		}
	}
	
	public void setPattern( List<Boolean> initialState )
	{
        if( initialState == null || initialState.size() == 0 ) return;
        List<EcoSystemState__c> EcoSystemStateList = [SELECT Id FROM EcoSystemState__c];
        if ( !EcoSystemStateList.isEmpty() ) delete EcoSystemStateList;
        
        if (BioMass == null) BioMass =
        [
            SELECT Alive__c, Index__c, X_Coordinate__c, Y_Coordinate__c,
                Neighbor_East__c, Neighbor_North__c, Neighbor_West__c , Neighbor_South__c,
                Neighbor_NE__c, Neighbor_NW__c , Neighbor_SE__c, Neighbor_SW__c
            FROM Lifeform__c
            ORDER BY Index__c ASC
        ];        
        if ( BioMass.isEmpty() ) return;

        Integer strlen = initialState.size();
        if(strlen < BioMass.size())
        {
        	while (strlen < BioMass.size())
        	{
        		initialState.add(true);
        		strlen = initialState.size();
        	}
        }
System.Debug('length ' + initialState.size() + ' initialState ' + initialState);
        for (Integer i = 0; i < BioMass.size() && i < strlen; i++) 
        {
            BioMass[i].Alive__c = initialState[i];
        }
        upsert BioMass;
	}

	public void resetEcosystem(Integer newSize, List<Boolean> initialState)
	{
		List<EcoSystemState__c> EcoSystemStateList = [SELECT Id FROM EcoSystemState__c];
		if ( !EcoSystemStateList.isEmpty() ) delete EcoSystemStateList;
		BioMass = [ SELECT Id FROM Lifeform__c ];
		if ( !BioMass.isEmpty() ) 
		{
			delete BioMass;
		    BioMass = new List<Lifeform__c>();
		}

		if ( newSize == 0 || newSize == null ) return;
        if (initialState == null) initialState = new List<Boolean>();
        Integer strlen = initialState.size();
        if(strlen < newSize)
        {
            while (strlen < newSize)
            {
                initialState.add(true);
                strlen = initialState.size();
            }
        }
System.Debug('reset length ' + initialState.size() + ' initialState ' + initialState);
        for (Integer i = 0; i < newSize && i < strlen; i++)
		{
			BioMass.add(new Lifeform__c(Index__c = i, Alive__c = initialState[i]) );
		}
		upsert BioMass;
		theWorld = new EcoSystemState__c ( NewestLife__c = BioMass[0].Id,  Direction__c = 'South' );
		insert theWorld;
		
		BioMass =
        [
            SELECT Alive__c, Index__c, X_Coordinate__c, Y_Coordinate__c,
                Neighbor_East__c, Neighbor_North__c, Neighbor_West__c , Neighbor_South__c,
                Neighbor_NE__c, Neighbor_NW__c , Neighbor_SE__c, Neighbor_SW__c
            FROM Lifeform__c
            ORDER BY Index__c ASC
        ];
	}

		//////////////////////////////////
		// Neighborhood Setup Functions //
		//   -WipeOutNeighbors          //
		//   -updateLocalNeighborhood   //
		//////////////////////////////////

	static void WipeOutNeighbors ( Lifeform__c me )
	{
		if ( me == null ) { System.Debug('WipeOutNeighbors without me'); return; }
		System.Debug( 'Wiping out neighbors for Lifeform ' + me.Index__c);
		me.Neighbor_East__c = me.Neighbor_SE__c =
			me.Neighbor_South__c = me.Neighbor_SW__c =
			me.Neighbor_West__c = me.Neighbor_NW__c =
			me.Neighbor_North__c = me.Neighbor_NE__c = null;
	}

	void updateLocalNeighborhood( Lifeform__c aLife )
	{
        // to the south
        Integer xCoord = Integer.valueOf(aLife.X_Coordinate__c);
        Integer yCoord = Integer.valueOf(aLife.Y_Coordinate__c);
Boolean PrintStuff = false;
If(  aLife.Index__c <= 11 )  //xCoord == 0 || yCoord == 0)
{
    PrintStuff = true;
    System.Debug( 'Start:Lifeform(' + xCoord + ',' + yCoord + '):' +
    aLife.Neighbor_North__c + ':' +
    aLife.Neighbor_NE__c + ':' +
    aLife.Neighbor_East__c + ':' +
    aLife.Neighbor_SE__c + ':' +
    aLife.Neighbor_South__c + ':' +
    aLife.Neighbor_SW__c + ':' +
    aLife.Neighbor_West__c + ':' +
    aLife.Neighbor_NW__c );
}
        Lifeform__c toTheSouth = (EcoSystem.get(xCoord) == null) ? null :
            EcoSystem.get(xCoord).get(yCoord+1);
If(PrintStuff)
{
}
        if (toTheSouth != null)
        {
            toTheSouth.Neighbor_North__c = aLife.Id;
            aLife.Neighbor_South__c = toTheSouth.Id;
        }
        
        // to the southwest
        Lifeform__c toTheSouthwest = (EcoSystem.get(xCoord-1) == null) ? null :
            EcoSystem.get(xCoord-1).get(yCoord+1);
        if (toTheSouthwest != null)
        {
            toTheSouthwest.Neighbor_NE__c = aLife.Id;
            aLife.Neighbor_SW__c = toTheSouthwest.Id;
        }
        
        // to the west
        Lifeform__c toTheWest = (EcoSystem.get(xCoord-1) == null) ? null :
            EcoSystem.get(xCoord-1).get(yCoord);
        if (toTheWest != null)
        {
            toTheWest.Neighbor_East__c = aLife.Id;
            aLife.Neighbor_West__c = toTheWest.Id;
        }
        
        // to the northwest
        Lifeform__c toTheNorthwest = (EcoSystem.get(xCoord-1) == null) ? null :
            EcoSystem.get(xCoord-1).get(yCoord-1);
        if (toTheNorthwest != null)
        {
            toTheNorthwest.Neighbor_SE__c = aLife.Id;
            aLife.Neighbor_NW__c = toTheNorthwest.Id;
        }
        
        // to the north
        Lifeform__c toTheNorth = (EcoSystem.get(xCoord) == null) ? null :
            EcoSystem.get(xCoord).get(yCoord-1);
        if (toTheNorth != null)
        {
            toTheNorth.Neighbor_South__c = aLife.Id;
            aLife.Neighbor_North__c = toTheNorth.Id;
        }
        
        // to the northeast
        Lifeform__c toTheNortheast = (EcoSystem.get(xCoord+1) == null) ? null :
            EcoSystem.get(xCoord+1).get(yCoord-1);
        if (toTheNortheast != null)
        {
            toTheNortheast.Neighbor_SW__c = aLife.Id;
            aLife.Neighbor_NE__c = toTheNortheast.Id;
        }
        
        // to the east
        Lifeform__c toTheEast = (EcoSystem.get(xCoord+1) == null) ? null :
            EcoSystem.get(xCoord+1).get(yCoord);
        if (toTheEast != null)
        {
            toTheEast.Neighbor_West__c = aLife.Id;
            aLife.Neighbor_East__c = toTheEast.Id;
        }
        
        // to the southeast
        Lifeform__c toTheSouthEast = (EcoSystem.get(xCoord+1) == null) ? null :
            EcoSystem.get(xCoord+1).get(yCoord+1);
        if (toTheSouthEast != null)
        {
            toTheSouthEast.Neighbor_NW__c = aLife.Id;
            aLife.Neighbor_SE__c = toTheSouthEast.Id;
        }
        
If(PrintStuff)
{
    System.Debug( 'End:Lifeform(' + xCoord + ',' + yCoord + '):' +
    aLife.Neighbor_North__c + ':' +
    aLife.Neighbor_NE__c + ':' +
    aLife.Neighbor_East__c + ':' +
    aLife.Neighbor_SE__c + ':' +
    aLife.Neighbor_South__c + ':' +
    aLife.Neighbor_SW__c + ':' +
    aLife.Neighbor_West__c + ':' +
    aLife.Neighbor_NW__c );
}
            
    }
    
        //////////////////////////////////////  // !!!untested
        // Generate Functions               //
        //   -Generate (used by all others) //
        //   -spiralGenerateLifePooled      //
        //   -GenerateRawPositions          //
        //   -GenerateRawNeightbors         //
        //////////////////////////////////////

    public void GenerateRawNeightbors( Boolean Torroid )
    {
        if (Torroid == null) Torroid = false;
        Map<Decimal,Lifeform__c> NorthEdge = new Map<Decimal,Lifeform__c>();    // Key is x coordinate
        Map<Decimal,Lifeform__c> SouthEdge = new Map<Decimal,Lifeform__c>();    // Key is x coordinate
        Map<Decimal,Lifeform__c> EastEdge = new Map<Decimal,Lifeform__c>();     // Key is y coordinate
        Map<Decimal,Lifeform__c> WestEdge = new Map<Decimal,Lifeform__c>();     // Key is y coordinate
    	for (Lifeform__c aLife : BioMass) 
    	{
    		updateLocalNeighborhood( aLife );
            if (aLife.Neighbor_North__c == null) NorthEdge.put(aLife.X_Coordinate__c, aLife);
            if (aLife.Neighbor_South__c == null) SouthEdge.put(aLife.X_Coordinate__c, aLife);
            if (aLife.Neighbor_East__c == null) EastEdge.put(aLife.Y_Coordinate__c, aLife);
            if (aLife.Neighbor_West__c == null) WestEdge.put(aLife.Y_Coordinate__c, aLife);
    	}
    	
    	if (Torroid)
    	{
    		for (Decimal theColumn : NorthEdge.keySet())
    		{
    			Lifeform__c top = NorthEdge.get(theColumn);
    			Lifeform__c bottom = SouthEdge.get(theColumn);
    			top.Neighbor_North__c = bottom.Id;
    			bottom.Neighbor_South__c = top.Id;
    		}
    		for (Decimal theRow : EastEdge.keySet())
            {
                Lifeform__c left = WestEdge.get(theRow);
                Lifeform__c right = EastEdge.get(theRow);
                right.Neighbor_East__c = left.Id;
                left.Neighbor_West__c = right.Id;
            }
    	}
    	update BioMass;
    }
    
    public void GenerateRawPositions( ) 
	{
		Integer SizeOfBiosphere = BioMass.size();
		Integer SizeX = Integer.valueOf( Math.Floor( Math.sqrt(SizeOfBiosphere) ) );
		Integer SizeY = Integer.valueOf( Math.Floor( ( SizeOfBiosphere / SizeX ) ) );
		Integer ArrayLimit = SizeX * SizeY;
		List<Lifeform__c> theExtra = new List<Lifeform__c>();
		while (BioMass.size() > ArrayLimit)
		{
			theExtra.add(BioMass.remove(0));
		}
		if (!theExtra.isEmpty()) delete theExtra;

		Lifeform__c spawn;
        Integer BioMassIndex = 0;
		for( Integer i = 0; i < SizeX; i++ )
		{
			spawn = BioMass[BioMassIndex];
            for( Integer j = 0; j < SizeY; j++ )
            {
                Integer coordX = i - SizeX / 2;
                Integer coordY = j - SizeY / 2;
                spawn.X_Coordinate__c = coordX;
                spawn.Y_Coordinate__c = coordY;
                Map<Integer,Lifeform__c> theColumn = EcoSystem.get(coordX);
                if ( theColumn == null )
                {
                    theColumn = new Map<Integer,Lifeform__c>();
                    EcoSystem.put(coordX, theColumn);
                }
                theColumn.put(coordY, spawn);
            }
            BioMassIndex++;       
        }
        
        update BioMass;
        theWorld.NewestLife__c = spawn.Id;
        update theWorld;
    }

	public void spiralGenerateLifePooled( )
	{
		String NewDirection = 'East';
		Integer SizeOfBiosphere = BioMass.size();
		if (SizeOfBiosphere == 0) return;
		if (theWorld == null) return;

		Lifeform__c last = BioMass[0];              
		last.X_Coordinate__c = last.Y_Coordinate__c = 0;

		WipeOutNeighbors(last);
		Map<Integer,Lifeform__c> firstColumn = new Map<Integer,Lifeform__c>{ 0 => last };
		EcoSystem.put(0, firstColumn);

		Lifeform__c spawn;
		for(Integer i = 1; i < SizeOfBiosphere; i++)
		{
			spawn = BioMass[i];
			WipeOutNeighbors(spawn);

			spawn.Alive__c = spawn.Alive__c == null ? (Math.random() >= 0.5 ? true : false) : spawn.Alive__c;

			NewDirection = MoveMap.get(NewDirection).move(spawn,last);

			Map<Integer,Lifeform__c> gridColumn = EcoSystem.get(Integer.valueOf(spawn.X_Coordinate__c));
			if ( gridColumn == null )
			{
System.Debug('Creating new gridColumn ' + spawn.Index__c + '(' + spawn.X_Coordinate__c + ',' + spawn.X_Coordinate__c +')');
				gridColumn = new Map<Integer,Lifeform__c>();
				EcoSystem.put(Integer.valueOf(spawn.X_Coordinate__c), gridColumn);
			}
			gridColumn.put(Integer.valueOf(spawn.Y_Coordinate__c), spawn);

			updateLocalNeighborhood( spawn );
			theWorld.Direction__c = NewDirection;
			last = spawn;
		}

		update Biomass;
		theWorld.NewestLife__c = spawn.Id;
		update theWorld;
	}

		////////////////////////////////////////////
		// Spiral Control Classes and Functions   //
		//   -Move (base class for all others)    //
		//   -tryToGoSouth                        //
		//   -tryToGoNorth                        //
		//   -tryToGoEast                         //
		//   -tryToGoWest                         //
		////////////////////////////////////////////

	// base class, used for the creation of a set of function pointers
	private abstract class Move
	{
		abstract String move( Lifeform__c me, Lifeform__c last );
	}

	private class tryToGoSouth extends Move
	{
		override String move(Lifeform__c me, Lifeform__c last)
		{
			if ( last.Neighbor_South__c == null )
			{
				setupLifeforms.GoSouth(me, last);
				return 'South'; 
			}

			// I tried to go south, but couldn't, so keep going East
			setupLifeforms.GoEast(me, last);
			return 'East'; 
		}
	}

	private class tryToGoWest extends Move
	{
		override String move(Lifeform__c me, Lifeform__c last)
		{
			if ( last.Neighbor_West__c == null )
			{
				setupLifeforms.GoWest(me, last);
				return 'West'; 
			}

			// I tried to go West, but couldn't, so keep going South
			setupLifeforms.GoSouth(me, last);
			return 'South';     
		}
	}

	private class tryToGoNorth extends Move
	{
		override String move(Lifeform__c me, Lifeform__c last)
		{
			if ( last.Neighbor_North__c == null )
			{
				setupLifeforms.GoNorth(me, last);
				return 'North';
			}

			// I tried to go North, but couldn't, so keep going West
			setupLifeforms.GoWest(me, last);
			return 'West';    
		}
	}

	private class tryToGoEast extends Move
	{
		override String move(Lifeform__c me, Lifeform__c last)
		{
			if ( last.Neighbor_East__c == null )
			{
				setupLifeforms.GoEast(me, last);
				return 'East';
			}

			// I tried to go East, but couldn't, so keep going North
			setupLifeforms.GoNorth(me, last);
			return 'North';    
		}
	}

	static void GoEast (Lifeform__c me, Lifeform__c last)
	{
		if (me == null || last == null) { System.Debug('GoEast with null args'); return; }
		last.Neighbor_East__c = me.Id;
		me.Neighbor_West__c = last.Id;
		me.X_Coordinate__c = last.X_Coordinate__c + 1;
		me.Y_Coordinate__c = last.Y_Coordinate__c;
	}

	static void GoWest (Lifeform__c me, Lifeform__c last)
	{
		if (me == null || last == null) { System.Debug('GoWest with null args'); return; }
		last.Neighbor_West__c = me.Id;
		me.Neighbor_East__c = last.Id;
		me.X_Coordinate__c = last.X_Coordinate__c - 1;
		me.Y_Coordinate__c = last.Y_Coordinate__c;
	}

	static void GoSouth (Lifeform__c me, Lifeform__c last)
	{
		if (me == null || last == null) { System.Debug('GoSouth with null args'); return; }
		last.Neighbor_South__c = me.Id;
		me.Neighbor_North__c = last.Id;
		me.X_Coordinate__c = last.X_Coordinate__c;
		me.Y_Coordinate__c = last.Y_Coordinate__c + 1;
	}

	static void GoNorth (Lifeform__c me, Lifeform__c last)
	{
		if (me == null || last == null) { System.Debug('GoNorth with null args'); return; }
		last.Neighbor_North__c = me.Id;
		me.Neighbor_South__c = last.Id;
		me.X_Coordinate__c = last.X_Coordinate__c;
		me.Y_Coordinate__c = last.Y_Coordinate__c - 1;
	}

        ////////////////////////////////////////////
        // Initial Pattern Functions              //
        ////////////////////////////////////////////
        
    public void clearEcosystem( Boolean doDML )
    {
    	for ( Lifeform__c aLife : BioMass )
    	{
    		aLife.Alive__c = false;
    	}
    	if (doDML) upsert BioMass;
    }
    
    public Boolean GosperGliderGun( Integer upperCornerx, Integer upperCornery, Boolean doDML )
    {
        // test limits
        if ( EcoSystem.get(upperCornerx + 36) == null ) return false;
        if ( EcoSystem.get(upperCornerx + 36).get(upperCornery + 9) == null ) return false;
        
        // 2x2 square on left
        EcoSystem.get(upperCornerx + 1).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 1).get(upperCornery + 6).Alive__c = true;
        EcoSystem.get(upperCornerx + 2).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 2).get(upperCornery + 6).Alive__c = true;
        
        // 2x2 square on right
        EcoSystem.get(upperCornerx + 35).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 35).get(upperCornery + 4).Alive__c = true;
        EcoSystem.get(upperCornerx + 36).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 36).get(upperCornery + 4).Alive__c = true;
        
        // Both guns are symetrical around the horizontal axis
        //left gun is 16 live lifeforms
        EcoSystem.get(upperCornerx + 13).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 13).get(upperCornery + 9).Alive__c = true;
        EcoSystem.get(upperCornerx + 14).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 14).get(upperCornery + 9).Alive__c = true;
        EcoSystem.get(upperCornerx + 12).get(upperCornery + 4).Alive__c = true;
        EcoSystem.get(upperCornerx + 12).get(upperCornery + 8).Alive__c = true;
        EcoSystem.get(upperCornerx + 16).get(upperCornery + 4).Alive__c = true;
        EcoSystem.get(upperCornerx + 16).get(upperCornery + 8).Alive__c = true;        
        EcoSystem.get(upperCornerx + 11).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 11).get(upperCornery + 7).Alive__c = true;
        EcoSystem.get(upperCornerx + 17).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 17).get(upperCornery + 7).Alive__c = true;
        EcoSystem.get(upperCornerx + 11).get(upperCornery + 6).Alive__c = true;
        EcoSystem.get(upperCornerx + 15).get(upperCornery + 6).Alive__c = true;
        EcoSystem.get(upperCornerx + 17).get(upperCornery + 6).Alive__c = true;
        EcoSystem.get(upperCornerx + 18).get(upperCornery + 6).Alive__c = true;
                //right gun is 12 live lifeforms
        EcoSystem.get(upperCornerx + 21).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 21).get(upperCornery + 4).Alive__c = true;
        EcoSystem.get(upperCornerx + 21).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 22).get(upperCornery + 3).Alive__c = true;
        EcoSystem.get(upperCornerx + 22).get(upperCornery + 4).Alive__c = true;
        EcoSystem.get(upperCornerx + 22).get(upperCornery + 5).Alive__c = true;
        EcoSystem.get(upperCornerx + 23).get(upperCornery + 2).Alive__c = true;
        EcoSystem.get(upperCornerx + 23).get(upperCornery + 6).Alive__c = true;        
        EcoSystem.get(upperCornerx + 25).get(upperCornery + 1).Alive__c = true;
        EcoSystem.get(upperCornerx + 25).get(upperCornery + 2).Alive__c = true;
        EcoSystem.get(upperCornerx + 25).get(upperCornery + 6).Alive__c = true;
        EcoSystem.get(upperCornerx + 25).get(upperCornery + 7).Alive__c = true;
        if (doDML) upsert BioMass;
        return true;
    }
}

//////////////////////////////////////////////
// Anonymous Code for Initialization

/*
Integer ecosystemX = 50; // length of square for a square ecosystem
Integer theLimit = 10;   // size of alternating runs of true/false
Integer ecosystemSize = ecosystemX * ecosystemX;
Boolean alive = true;
Integer j = 0;

List<Boolean> setString = new List<Boolean>();
for(Integer i = 0; i < ecosystemSize; i++)
{
    setString.add( alive ? true : false );
    if (j == theLimit - 1)
    {
        j = 0;
        alive = !alive;
    }
    else j++;
}

setupLifeforms NES = new setupLifeforms();
NES.resetEcosystem(ecosystemSize, setString);
NES.spiralGenerateLifePooled(  );
*/