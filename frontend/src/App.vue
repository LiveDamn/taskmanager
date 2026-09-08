<script setup>
import { computed, onMounted, ref } from 'vue'

const tasks = ref([])
const title = ref('')
const description = ref('')
const filter = ref('all')
const loading = ref(true)
const submitting = ref(false)
const error = ref('')

const visibleTasks = computed(() => {
  if (filter.value === 'active') return tasks.value.filter((task) => !task.completed)
  if (filter.value === 'done') return tasks.value.filter((task) => task.completed)
  return tasks.value
})
const activeCount = computed(() => tasks.value.filter((task) => !task.completed).length)
const completedCount = computed(() => tasks.value.filter((task) => task.completed).length)

async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
  if (!response.ok) throw new Error('Не удалось выполнить запрос')
  return response.status === 204 ? null : response.json()
}

async function loadTasks() {
  loading.value = true
  error.value = ''
  try {
    tasks.value = await request('/api/tasks')
  } catch {
    error.value = 'Не удаётся подключиться к API. Проверьте, запущен ли сервер.'
  } finally {
    loading.value = false
  }
}

async function addTask() {
  if (!title.value.trim() || submitting.value) return
  submitting.value = true
  error.value = ''
  try {
    const task = await request('/api/tasks', {
      method: 'POST',
      body: JSON.stringify({ title: title.value, description: description.value }),
    })
    tasks.value.unshift(task)
    title.value = ''
    description.value = ''
  } catch {
    error.value = 'Задачу не удалось сохранить.'
  } finally {
    submitting.value = false
  }
}

async function toggleTask(task) {
  const previous = task.completed
  task.completed = !previous
  try {
    const updated = await request(`/api/tasks/${task.id}`, {
      method: 'PATCH',
      body: JSON.stringify({ completed: task.completed }),
    })
    Object.assign(task, updated)
  } catch {
    task.completed = previous
    error.value = 'Статус не удалось обновить.'
  }
}

async function removeTask(task) {
  try {
    await request(`/api/tasks/${task.id}`, { method: 'DELETE' })
    tasks.value = tasks.value.filter((item) => item.id !== task.id)
  } catch {
    error.value = 'Задачу не удалось удалить.'
  }
}

function formatDate(value) {
  return new Intl.DateTimeFormat('ru-RU', { day: 'numeric', month: 'short' }).format(new Date(value))
}

onMounted(loadTasks)
</script>

<template>
  <main class="page-shell">
    <header class="topbar">
      <div class="brand-mark" aria-hidden="true">✓</div>
      <div>
        <p class="eyebrow">личный органайзер</p>
        <h1>Дела на сегодня</h1>
      </div>
      <div class="topbar-date">{{ new Intl.DateTimeFormat('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }).format(new Date()) }}</div>
    </header>

    <section class="intro-grid">
      <div class="intro-copy">
        <p class="section-kicker">Фокус дня</p>
        <h2>Маленькие шаги<br /><em>складываются в большое.</em></h2>
        <p class="intro-note">Запишите то, что важно сделать, и освободите голову для следующего шага.</p>
      </div>
      <div class="stats-panel">
        <div class="stat"><strong>{{ activeCount }}</strong><span>в работе</span></div>
        <div class="stat"><strong>{{ completedCount }}</strong><span>завершено</span></div>
        <div class="progress-track"><span :style="{ width: tasks.length ? `${(completedCount / tasks.length) * 100}%` : '0%' }"></span></div>
      </div>
    </section>

    <section class="workspace">
      <form class="task-form" @submit.prevent="addTask">
        <div class="form-heading"><span class="plus">+</span><span>Новая задача</span></div>
        <label>
          <span>Что нужно сделать?</span>
          <input v-model="title" maxlength="200" placeholder="Например, подготовить презентацию" autofocus />
        </label>
        <label>
          <span>Детали <small>необязательно</small></span>
          <textarea v-model="description" maxlength="1000" rows="3" placeholder="Добавьте немного контекста"></textarea>
        </label>
        <button class="primary-button" type="submit" :disabled="submitting || !title.trim()">{{ submitting ? 'Сохраняем...' : 'Добавить задачу' }} <span>↗</span></button>
      </form>

      <div class="list-panel">
        <div class="list-heading">
          <div><p class="section-kicker">Ваш список</p><h2>Задачи <span>{{ tasks.length }}</span></h2></div>
          <div class="filters" role="group" aria-label="Фильтр задач">
            <button :class="{ selected: filter === 'all' }" @click="filter = 'all'">Все</button>
            <button :class="{ selected: filter === 'active' }" @click="filter = 'active'">В работе</button>
            <button :class="{ selected: filter === 'done' }" @click="filter = 'done'">Готово</button>
          </div>
        </div>

        <p v-if="error" class="error-message">{{ error }}</p>
        <div v-if="loading" class="empty-state"><div class="loader"></div><p>Загружаем список...</p></div>
        <div v-else-if="!visibleTasks.length" class="empty-state"><div class="empty-icon">○</div><h3>{{ tasks.length ? 'Здесь пока пусто' : 'Список чист' }}</h3><p>{{ tasks.length ? 'Попробуйте выбрать другой фильтр.' : 'Добавьте первую задачу слева.' }}</p></div>
        <div v-else class="task-list">
          <article v-for="task in visibleTasks" :key="task.id" class="task-item" :class="{ completed: task.completed }">
            <button class="check-button" :aria-label="task.completed ? 'Вернуть в работу' : 'Отметить выполненной'" @click="toggleTask(task)">{{ task.completed ? '✓' : '' }}</button>
            <div class="task-content"><h3>{{ task.title }}</h3><p v-if="task.description">{{ task.description }}</p><time>{{ formatDate(task.created_at) }}</time></div>
            <button class="delete-button" aria-label="Удалить задачу" @click="removeTask(task)">×</button>
          </article>
        </div>
      </div>
    </section>
    <footer><span class="online-dot"></span> Данные синхронизируются с PostgreSQL</footer>
  </main>
</template>
