/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2002 The Caudium Group
 * Copyright � 1994-2001 Roxen Internet Software
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

constant cvs_version = "$Id$";

  // This is the cache object that is visible to the rest of caudium.
  // Everything underneath this object is to be considered black voodoo
  // magic from the point of view of any module that uses it.
  // store() and retrieve() are totally wrong. I will re-write the API to
  // use something akin to response mappings from caudiumlib, say cachelib?
  // say, cache_file_object(), cache_pike_object(), and cache_string_object()
  // or whatever. Basically then we already know what the data is and
  // a) whether we can save it to disk when it gets old, and
  // b) whether we can use nbio to copy it around and stuff.

object ram_cache;
object disk_cache;
string namespace;
int max_object_ram;
int max_object_disk;
string path;

void create( string _namespace, string _path, int _max_object_ram, int _max_object_disk, program rcache, program dcache ) {
	// Create the cache, and memory management.
	// namespace: The namespace of the object, ie what virtual
	//            server the data is for - or maybe for specialised
	//            caching inside a certail module.
  namespace = _namespace;
  max_object_ram = _max_object_ram;
  max_object_disk = _max_object_disk;
  path = _path;
  disk_cache = dcache( namespace, path );
  ram_cache = rcache( namespace, disk_cache );
}

void set_sizes( int _max_object_ram, int _max_object_disk ) {
  max_object_ram = _max_object_ram;
  max_object_disk = _max_object_disk;
}

int ram_usage() {
  return ram_cache->usage();
}

int disk_usage() {
  return disk_cache->usage();
}

mapping status() {
  int ram_hitrate;
  int disk_hitrate;
  int total_hitrate;
  if ( ram_cache->misses() ) {
    ram_hitrate = (int)(ram_cache->hits() / ram_cache->misses() * 100);
  }
  if ( disk_cache->misses() ) {
    disk_hitrate = (int)(disk_cache->hits() / ram_cache->misses() * 100);
  }
  total_hitrate = ram_hitrate + disk_hitrate / 2;
  return ([
    "fast_hits" : ram_cache->hits(),
    "fast_misses" : ram_cache->misses(),
    "fast_object_count" : ram_cache->object_count(),
    "slow_hits" : disk_cache->hits(),
    "slow_misses" : disk_cache->misses(),
    "slow_object_count" : disk_cache->object_count(),
    "total_hits" : ram_cache->hits() + disk_cache->hits(),
    "total_misses" : disk_cache->misses() + disk_cache->misses(),
    "total_object_count" : ram_cache->object_count() + disk_cache->object_count(),
    "ram_hitrate" : ram_hitrate,
    "disk_hitrate" : disk_hitrate,
    "total_hitrate" : total_hitrate
  ]);
}

void store( mapping cache_response ) {
	// Store an object in the cache, if we can.
	// Check to see if the object is too big, if it is then check to see
	// if it is a datatype that we can save to disk. If so then do it,
	// else just ignore it, it will just have to be a cache miss for all
	// eternity.
	// Check to see whether it is an NBIO capable object, if so then use
	// two_way_nbio to get it into the ram cache.
	// If it's not then we may as well block and copy it to rem_cache
	// After talking to hubbe I have learned that nbio wont work when
	// writing to disk. screwed, eh?
  if ( cache_response->size > max_object_ram ) {
    if ( cache_response->disk_cache ) {
      if ( cache_response->size > max_object_disk ) {
        return 0;
      }
      disk_cache->store( cache_response );
      return 0;
    }
  }
  ram_cache->store( cache_response );
}

void|mapping retrieve( string name, void|int objectonly ) {
	// Search the caches for the object.
	// if there is a matching object in the ram_cache then return
	// it to the caller, else check the disk_cache.
	// Else, just return nothing.
  mixed _object = ram_cache->retrieve( name );
  if ( mappingp( _object ) ) {
    if ( objectonly ) {
      return _object->object;
    }
    return _object;
  }
  _object = disk_cache->retrieve( name );
  if ( mappingp( _object ) ) {
    if ( _object->size < max_object_ram ) {
      ram_cache->store( _object );
    }
    if ( objectonly ) {
      return _object->object;
    }
    return _object;
  }
}

void refresh( string name ) {
	// Forcibly refresh an object in the cache
	// name: The name of the object to retrieve.
  ram_cache->refresh( name );
  disk_cache->refresh( name );
}

void free_ram( int nbytes ) {
#ifdef DEBUG
  write( "RAM_CACHE( " + namespace + " ): Freeing " + nbytes + " RAM\n" );
#endif
  ram_cache->free( nbytes );
}

void free_disk( int nbytes ) {
  disk_cache->free( nbytes );
}

void flush() {
	// Flush the entire cache
  ram_cache->flush();
  disk_cache->flush();
}

void stop() {
	// Save the state of the cache
  ram_cache->stop();
  disk_cache->stop();
}
