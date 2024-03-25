<script lang="ts">
	import '../app.css';

	import Menubar from '$lib/menu/Menubar.svelte';
	import Contextbar from '$lib/menu/Contextbar.svelte';
	import { errors, removeError } from '$lib/error';
	import { fly, slide } from 'svelte/transition';
	import { backOut, expoOut } from 'svelte/easing';
	import { Button } from 'bits-ui';
	import Icon from '@iconify/svelte';
</script>

<main
	class="h-screen overflow-hidden flex flex-col rounded-lg border border-gray-600 bg-gray-800 relative"
>
	<Menubar />
	<Contextbar />

	<slot />

	<div class="bottom-0 right-0 w-full max-w-[50rem] p-2 gap-1 absolute flex flex-col-reverse">
		{#each $errors as error, i}
			<div
				class="bg-red-600 pl-4 pr-8 py-2 rounded-md text-lg relative" 
				transition:slide={{ duration: 200, easing: expoOut }}
			>
				<span class="text-red-200">Failed to execute '{error.name}' -</span>
				<span class="text-red-100 font-medium ml-1">{error.message}</span>

				<Button.Root class="absolute top-3 right-3" on:click={() => removeError(i)}>
					<Icon icon="mdi:close" class="text-red-200" />
				</Button.Root>
			</div>
		{/each}
	</div>
</main>